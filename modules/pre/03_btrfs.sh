#!/usr/bin/env bash
set -euo pipefail

echo "Configurando subvolumes adicionais BTRFS"

ROOT_PART=$(findmnt -no SOURCE / | sed 's/\[.*//')
UUID=$(blkid -s UUID -o value "$ROOT_PART")

echo "Root detectado: $ROOT_PART"
echo "UUID detectado: $UUID"

echo "Montando subvolid=5 temporariamente..."
mkdir -p /mnt/btrfs-root
mount -o subvolid=5 "$ROOT_PART" /mnt/btrfs-root

create_subvolume_if_not_exists() {
  local name="$1"

  if btrfs subvolume list /mnt/btrfs-root | grep -q "path $name$"; then
    echo "Subvolume $name ja existe. Pulando..."
  else
    echo "Criando subvolume $name..."
    btrfs subvolume create "/mnt/btrfs-root/$name"
  fi
}

echo "Criando subvolumes adicionais se nao existirem..."
create_subvolume_if_not_exists "@docker"
create_subvolume_if_not_exists "@cache"

umount /mnt/btrfs-root
rmdir /mnt/btrfs-root

echo "Parando Docker (se existir)..."
systemctl stop docker 2>/dev/null || true

echo "Criando mountpoints..."
mkdir -p /var/lib/docker
mkdir -p /var/cache
mkdir -p /var/cache/pacman/pkg

echo "Atualizando /etc/fstab..."

add_fstab_entry() {
  local subvol="$1"
  local mountpoint="$2"

  if ! grep -q "subvol=$subvol" /etc/fstab; then
    echo "Adicionando $subvol ao fstab..."
    echo "UUID=$UUID  $mountpoint  btrfs  subvol=$subvol,compress=zstd,noatime  0 0" >>/etc/fstab
  else
    echo "$subvol ja esta no fstab. Pulando..."
  fi
}

add_fstab_entry "@docker" "/var/lib/docker"
add_fstab_entry "@cache" "/var/cache"

echo "Recarregando systemd..."
systemctl daemon-reload

echo "Montando novos subvolumes..."
mount -a

echo "Iniciando Docker novamente..."
systemctl start docker 2>/dev/null || true

echo "Configuracao concluida com sucesso"
