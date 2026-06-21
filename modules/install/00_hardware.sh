#!/bin/bash
#
# Deteccao automatica de CPU e GPU para instalar microcode e drivers corretos.
#
# Por padrao detecta o hardware automaticamente (funciona com qualquer
# combinacao, inclusive maquinas mistas como Ryzen + GeForce). Pode ser
# sobrescrito pelas flags --cpu e --gpu (variaveis FORCE_CPU_VENDOR /
# FORCE_GPU_VENDOR exportadas pelo install.sh).
#
# Roda tanto no modo padrao quanto no modo gaming.

# Detecta o fabricante da CPU: "amd", "intel" ou "unknown".
detect_cpu_vendor() {
  if [ -n "$FORCE_CPU_VENDOR" ]; then
    echo "$FORCE_CPU_VENDOR"
    return
  fi

  case "$(grep -m1 -oE 'AuthenticAMD|GenuineIntel' /proc/cpuinfo)" in
  AuthenticAMD) echo "amd" ;;
  GenuineIntel) echo "intel" ;;
  *) echo "unknown" ;;
  esac
}

# Detecta os fabricantes de GPU presentes (pode haver mais de um, ex: iGPU
# Intel + dGPU NVIDIA). Retorna lista separada por espaco: ex "amd nvidia".
detect_gpu_vendors() {
  if [ -n "$FORCE_GPU_VENDOR" ]; then
    echo "$FORCE_GPU_VENDOR"
    return
  fi

  if ! command -v lspci &>/dev/null; then
    echo "Aviso: lspci (pciutils) nao encontrado; nao foi possivel detectar a GPU." >&2
    return
  fi

  local lspci_out gpus=""
  lspci_out=$(lspci 2>/dev/null | grep -iE 'vga|3d|display')

  echo "$lspci_out" | grep -iqE 'nvidia' && gpus="$gpus nvidia"
  echo "$lspci_out" | grep -iqE 'amd|ati|radeon' && gpus="$gpus amd"
  echo "$lspci_out" | grep -iqE 'intel' && gpus="$gpus intel"

  echo "$gpus" | xargs # remove espacos extras
}

# Pacotes de microcode por fabricante de CPU.
get_cpu_packages() {
  case "$1" in
  amd) echo "amd-ucode" ;;
  intel) echo "intel-ucode" ;;
  esac
}

# Pacotes de driver/Vulkan (com suporte 32-bit p/ Steam/Proton) por GPU.
get_gpu_packages() {
  case "$1" in
  amd)
    echo "mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon" \
      "vulkan-icd-loader lib32-vulkan-icd-loader xf86-video-amdgpu"
    ;;
  intel)
    echo "mesa lib32-mesa vulkan-intel lib32-vulkan-intel" \
      "vulkan-icd-loader lib32-vulkan-icd-loader intel-media-driver"
    ;;
  nvidia)
    echo "nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings" \
      "egl-wayland vulkan-icd-loader lib32-vulkan-icd-loader"
    ;;
  esac
}

# Popula o array global HARDWARE_PACKAGES com microcode + drivers detectados.
collect_hardware_packages() {
  HARDWARE_PACKAGES=()

  local cpu_vendor gpu_vendors
  cpu_vendor=$(detect_cpu_vendor)
  gpu_vendors=$(detect_gpu_vendors)

  echo "CPU detectada: ${cpu_vendor}" >&2
  echo "GPU(s) detectada(s): ${gpu_vendors:-nenhuma}" >&2

  local cpu_pkgs
  cpu_pkgs=$(get_cpu_packages "$cpu_vendor")
  [ -n "$cpu_pkgs" ] && HARDWARE_PACKAGES+=($cpu_pkgs)

  local g gpu_pkgs
  for g in $gpu_vendors; do
    gpu_pkgs=$(get_gpu_packages "$g")
    [ -n "$gpu_pkgs" ] && HARDWARE_PACKAGES+=($gpu_pkgs)
  done

  if [ ${#HARDWARE_PACKAGES[@]} -eq 0 ]; then
    echo "Aviso: nenhum pacote de hardware detectado. Use --cpu/--gpu para forcar." >&2
  fi
}
