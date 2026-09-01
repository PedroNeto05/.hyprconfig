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

# Detecta se a maquina e um notebook. Retorna 0 (verdadeiro) ou 1 (falso).
#
# Usa tres sinais, em ordem de confiabilidade:
#   1. presenca de bateria em /sys/class/power_supply/BAT*
#   2. o chassis reportado pelo systemd (hostnamectl)
#   3. o chassis_type do DMI/SMBIOS (8=portatil, 9=laptop, 10=notebook,
#      11=handheld, 14=subnotebook, 30=tablet, 31=conversivel, 32=destacavel)
detect_is_laptop() {
  local bat
  for bat in /sys/class/power_supply/BAT*; do
    [ -e "$bat" ] && return 0
  done

  if command -v hostnamectl &>/dev/null; then
    case "$(hostnamectl chassis 2>/dev/null)" in
    laptop | notebook | convertible | tablet | handset) return 0 ;;
    esac
  fi

  if [ -r /sys/class/dmi/id/chassis_type ]; then
    case "$(cat /sys/class/dmi/id/chassis_type)" in
    8 | 9 | 10 | 11 | 14 | 30 | 31 | 32) return 0 ;;
    esac
  fi

  return 1
}

# Detecta GPU hibrida (iGPU + dGPU, tipico de notebook gamer/workstation).
detect_hybrid_gpu() {
  local count
  count=$(detect_gpu_vendors | wc -w)
  [ "$count" -ge 2 ]
}

# Popula LAPTOP_PACKAGES com os extras condicionais de notebook e exporta
# IS_LAPTOP para que o post-install saiba quais servicos habilitar.
collect_laptop_packages() {
  LAPTOP_PACKAGES=()

  if ! detect_is_laptop; then
    export IS_LAPTOP=false
    echo "Chassi: desktop (nenhum pacote de notebook sera instalado)." >&2
    return
  fi

  export IS_LAPTOP=true
  echo "Chassi: notebook (bateria/DMI detectados)." >&2

  # thermald so existe e so faz sentido em CPUs Intel.
  if [ "$(detect_cpu_vendor)" = "intel" ]; then
    echo "CPU Intel em notebook: adicionando thermald." >&2
    LAPTOP_PACKAGES+=(thermald)
  fi

  # Em GPU hibrida (iGPU + dGPU) o switcheroo-control expõe o "Launch with
  # discrete GPU" para os apps e evita acordar a dGPU sem necessidade.
  if detect_hybrid_gpu; then
    echo "GPU hibrida detectada: adicionando switcheroo-control." >&2
    LAPTOP_PACKAGES+=(switcheroo-control)
    export HAS_HYBRID_GPU=true
  else
    export HAS_HYBRID_GPU=false
  fi
}
