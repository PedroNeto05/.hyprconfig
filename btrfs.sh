echo "===== Configurando subvolumes adicionais BTRFS ====="

ROOT_PART=$(findmnt -no SOURCE /)
UUID=$(blkid -s UUID -o value "$ROOT_PART")

echo "Root detectado: $ROOT_PART"
echo "UUID detectado: $UUID"

echo "Montando subvolid=5 temporariamente..."
mkdir -p /mnt/btrfs-root
mount -o subvolid=5 "$ROOT_PART" /mnt/btrfs-root

echo "Criando subvolumes @docker, @log e @cache..."
btrfs subvolume create /mnt/btrfs-root/@docker
btrfs subvolume create /mnt/btrfs-root/@log
btrfs subvolume create /mnt/btrfs-root/@cache

umount /mnt/btrfs-root
rmdir /mnt/btrfs-root

echo "Parando Docker (se existir)..."
systemctl stop docker 2>/dev/null || true

echo "Movendo dados atuais para backup temporário..."
mkdir -p /.old-btrfs-data

mv /var/lib/docker /.old-btrfs-data/docker 2>/dev/null || true
mv /var/log /.old-btrfs-data/log
mv /var/cache /.old-btrfs-data/cache

mkdir -p /var/lib/docker /var/log /var/cache

echo "Atualizando /etc/fstab..."

cat <<EOF >>/etc/fstab
UUID=$UUID  /var/lib/docker btrfs subvol=@docker,compress=zstd,noatime 0 0
UUID=$UUID  /var/log        btrfs subvol=@log,compress=zstd,noatime 0 0
UUID=$UUID  /var/cache      btrfs subvol=@cache,compress=zstd,noatime 0 0
EOF

echo "Montando novos subvolumes..."
mount -a

echo "Restaurando dados..."
# O uso do cp -a garante que permissões, donos (chown) e links simbólicos sejam mantidos perfeitamente
cp -a /.old-btrfs-data/docker/. /var/lib/docker/ 2>/dev/null || true
cp -a /.old-btrfs-data/log/. /var/log/
cp -a /.old-btrfs-data/cache/. /var/cache/

rm -rf /.old-btrfs-data

echo "Iniciando Docker novamente..."
systemctl start docker 2>/dev/null || true

echo "===== Configurando Snapper para /home ====="

# Cria a configuração do Snapper especificamente para o subvolume da home
snapper -c home create-config /home 2>/dev/null || echo "Configuração do Snapper para /home já existe."

# Ajusta as permissões para que usuários comuns não acessem os snapshots de outros
chmod 750 /home/.snapshots 2>/dev/null || true

echo "===== Configuração concluída com sucesso ====="
