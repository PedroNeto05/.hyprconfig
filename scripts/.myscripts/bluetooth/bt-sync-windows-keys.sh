#!/bin/bash
#
# Copia as chaves de pareamento Bluetooth clássico (BR/EDR) do Windows para o
# BlueZ, para que os dois sistemas do dual boot usem a MESMA chave com cada
# aparelho.
#
# Sintoma que este script resolve: depois de usar o aparelho no Windows, o
# Linux não conecta mais ("Connection Failed: Unknown error" no blueman) e o
# log do bluetoothd mostra, a cada tentativa:
#   avdtp_connect_cb() connect to XX:XX:...: Permission denied (13)
#   avdtp_connect_cb() connect to XX:XX:...: Too many levels of symbolic links (40)
# (13 = falha de autenticação; 40 = "Repeated Attempts" da caixa.)
# O aparelho guarda uma só chave por endereço de adaptador, e Windows e Linux
# usam o mesmo adaptador: quem pareou por último invalida a chave do outro.
#
# Uso:  sudo bash ~/.myscripts/bluetooth/bt-sync-windows-keys.sh
#
# - Monta a partição do Windows SOMENTE LEITURA e desmonta em seguida.
# - Faz backup de /var/lib/bluetooth/<adaptador> em /root antes de alterar.
# - Só altera aparelhos que já estão pareados nos dois sistemas.
# - Nenhuma chave é exibida no terminal.
# - Aparelhos BLE (Low Energy) não são cobertos.
#
# Variáveis opcionais (detecção automática quando vazias):
#   ADAPTER=50:28:4A:62:25:9F   endereço do adaptador Bluetooth
#   WIN_DEV=/dev/sdc2           partição do Windows (C:)
# Depende de: uv (baixa o pacote Python regipy num cache temporário).

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo."; exit 1; }
command -v uv >/dev/null || { echo "Erro: uv não encontrado."; exit 1; }

WORK=$(mktemp -d)
MNT=$WORK/win
mkdir -p "$MNT"
STOPPED_BT=false
cleanup() {
  mountpoint -q "$MNT" && umount "$MNT"
  rm -rf "$WORK"
  if [ "$STOPPED_BT" = true ]; then
    systemctl is-active -q bluetooth.service || systemctl start bluetooth.service
  fi
}
trap cleanup EXIT

# --- Adaptador -------------------------------------------------------------
if [ -z "${ADAPTER:-}" ]; then
  mapfile -t adapters < <(find /var/lib/bluetooth -mindepth 1 -maxdepth 1 -type d \
    -regextype posix-extended -regex '.*/([0-9A-F]{2}:){5}[0-9A-F]{2}' -printf '%f\n')
  if [ "${#adapters[@]}" -ne 1 ]; then
    echo "Encontrei ${#adapters[@]} adaptadores em /var/lib/bluetooth; defina ADAPTER=XX:XX:..."
    exit 1
  fi
  ADAPTER=${adapters[0]}
fi
BTDIR=/var/lib/bluetooth/$ADAPTER
[ -d "$BTDIR" ] || { echo "Erro: $BTDIR não existe."; exit 1; }
echo "Adaptador: $ADAPTER"

# --- Partição do Windows -----------------------------------------------------
HIVE=Windows/System32/config/SYSTEM
if [ -z "${WIN_DEV:-}" ]; then
  while read -r dev fstype; do
    [ "$fstype" = ntfs ] || continue
    if mount -o ro "$dev" "$MNT" 2>/dev/null; then
      [ -f "$MNT/$HIVE" ] && WIN_DEV=$dev
      umount "$MNT"
      [ -n "${WIN_DEV:-}" ] && break
    fi
  done < <(lsblk -rno PATH,FSTYPE)
  [ -n "${WIN_DEV:-}" ] || { echo "Erro: partição do Windows não encontrada; defina WIN_DEV."; exit 1; }
fi
echo "Windows: $WIN_DEV"

echo "Lendo o registro do Windows (somente leitura)..."
mount -o ro "$WIN_DEV" "$MNT"
cp "$MNT/$HIVE" "$MNT/$HIVE.LOG1" "$MNT/$HIVE.LOG2" "$WORK"/
umount "$MNT"

echo "Parando o bluetooth.service..."
STOPPED_BT=true
systemctl stop bluetooth.service

BACKUP=/root/bluetooth-backup-$(date +%Y%m%d-%H%M%S)
cp -a "$BTDIR" "$BACKUP"
echo "Backup dos pareamentos: $BACKUP"

UV_CACHE_DIR=$WORK/uv-cache uv run -q --no-project --with regipy -- \
  python -I - "$WORK" "$BTDIR" "$ADAPTER" <<'PY'
import os, re, sys
from regipy.registry import RegistryHive
from regipy.recovery import apply_transaction_logs

work, btdir, adapter = sys.argv[1:4]
base = os.path.join(work, "SYSTEM")
hive_path = base
try:
    rec = os.path.join(work, "SYSTEM.recovered")
    apply_transaction_logs(base, os.path.join(work, "SYSTEM.LOG1"),
                           os.path.join(work, "SYSTEM.LOG2"), rec)
    hive_path = rec
except Exception as e:
    print(f"Aviso: logs de transação não aplicados ({e}); usando o hive base.")

hive = RegistryHive(hive_path)

def get_key(path):
    for p in (path, "\\" + path):
        try:
            return hive.get_key(p)
        except Exception:
            pass
    raise SystemExit(f"Chave não encontrada no registro: {path}")

current = None
for v in get_key("Select").iter_values():
    if v.name == "Current":
        current = int(v.value)
akey = adapter.replace(":", "").lower()
keys = get_key(f"ControlSet{current:03d}\\Services\\BTHPORT\\Parameters\\Keys\\{akey}")

def to_hex(value):
    if isinstance(value, (bytes, bytearray)):
        return bytes(value).hex().upper()
    return re.sub(r"[^0-9A-Fa-f]", "", str(value)).upper()

found = False
for v in keys.iter_values():
    if not re.fullmatch(r"[0-9a-f]{12}", v.name):
        continue
    mac = ":".join(v.name[i:i + 2] for i in range(0, 12, 2)).upper()
    new_key = to_hex(v.value)
    info = os.path.join(btdir, mac, "info")
    if len(new_key) != 32:
        print(f"{mac}: chave do Windows com formato inesperado, ignorado")
        continue
    if not os.path.exists(info):
        print(f"{mac}: pareado só no Windows, ignorado")
        continue
    lines = open(info).read().split("\n")
    name, section, state = mac, None, "sem [LinkKey] no Linux, ignorado"
    for i, line in enumerate(lines):
        m = re.fullmatch(r"\[(.+)\]", line.strip())
        if m:
            section = m.group(1)
            continue
        if section == "General" and line.startswith("Name="):
            name = f"{line[5:]} ({mac})"
        if section == "LinkKey" and line.startswith("Key="):
            if line[4:] == new_key:
                state = "já estava igual"
            else:
                lines[i] = "Key=" + new_key
                state = "chave atualizada"
    if state == "chave atualizada":
        with open(info, "w") as f:
            f.write("\n".join(lines))
    found = True
    print(f"{name}: {state}")

if not found:
    print("Nenhum aparelho pareado no Windows para este adaptador.")
PY

echo "Iniciando o bluetooth.service..."
systemctl start bluetooth.service
STOPPED_BT=false
echo "Pronto. Tente conectar o aparelho no Linux."
