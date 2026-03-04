echo "===== Configurando subvolumes adicionais BTRFS ====="

ROOT_PART=$(findmnt -no SOURCE / | sed 's/\[.*//')
UUID=$(blkid -s UUID -o value "$ROOT_PART")

echo "Root detectado: $ROOT_PART"
echo "UUID detectado: $UUID"

echo "Montando subvolid=5 temporariamente..."
mkdir -p /mnt/btrfs-root
mount -o subvolid=5 "$ROOT_PART" /mnt/btrfs-root

echo "Criando subvolumes adicionais se não existirem..."

# Função para validar e criar subvolume
create_subvolume_if_not_exists() {
  local name="$1"

  if btrfs subvolume list /mnt/btrfs-root | grep -q "path $name$"; then
    echo "Subvolume $name já existe. Pulando..."
  else
    echo "Criando subvolume $name..."
    btrfs subvolume create "/mnt/btrfs-root/$name"
  fi
}

create_subvolume_if_not_exists "@docker"
create_subvolume_if_not_exists "@log"
create_subvolume_if_not_exists "@cache"

umount /mnt/btrfs-root
rmdir /mnt/btrfs-root

echo "Parando Docker (se existir)..."
systemctl stop docker 2>/dev/null || true

echo "Movendo dados atuais para backup temporário..."
mkdir -p /.old-btrfs-data

mv /var/lib/docker /.old-btrfs-data/docker 2>/dev/null || true
mv /var/log /.old-btrfs-data/log 2>/dev/null || true
mv /var/cache /.old-btrfs-data/cache 2>/dev/null || true

mkdir -p /var/lib/docker /var/log /var/cache

echo "Atualizando /etc/fstab..."

# Só adiciona entradas se ainda não existirem
grep -q "@docker" /etc/fstab || cat <<EOF >>/etc/fstab
UUID=$UUID  /var/lib/docker btrfs subvol=@docker,compress=zstd,noatime 0 0
EOF

grep -q "@log" /etc/fstab || cat <<EOF >>/etc/fstab
UUID=$UUID  /var/log        btrfs subvol=@log,compress=zstd,noatime 0 0
EOF

grep -q "@cache" /etc/fstab || cat <<EOF >>/etc/fstab
UUID=$UUID  /var/cache      btrfs subvol=@cache,compress=zstd,noatime 0 0
EOF

echo "Montando novos subvolumes..."
mount -a

echo "Restaurando dados..."
cp -a /.old-btrfs-data/docker/. /var/lib/docker/ 2>/dev/null || true
cp -a /.old-btrfs-data/log/. /var/log/ 2>/dev/null || true
cp -a /.old-btrfs-data/cache/. /var/cache/ 2>/dev/null || true

rm -rf /.old-btrfs-data

echo "Iniciando Docker novamente..."
systemctl start docker 2>/dev/null || true

echo "===== Configurando Snapper para /home ====="

snapper -c home create-config /home 2>/dev/null ||
  echo "Configuração do Snapper para /home já existe."

chmod 750 /home/.snapshots 2>/dev/null || true

echo "===== Configuração concluída com sucesso ====="
