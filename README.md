# Instalação do Ambiente

**⚠️ Aviso Importante: Esta configuração foi desenvolvida e funciona exclusivamente no Arch Linux.**

Siga as instruções abaixo para configurar tudo corretamente.

## Instalação Principal

Primeiro, clone este repositório para a sua máquina:

```bash
git clone https://github.com/PedroNeto05/.hyprconfig
cd .hyprconfig
```

Após clonar o repositório, execute o script de pré-instalação para preparar o sistema e, em seguida, rode a instalação principal:

```bash
./pre.sh
./install.sh
```

### Seleção de CPU e GPU

Por padrão, o `install.sh` **detecta automaticamente** o fabricante da CPU e da GPU e
instala o microcode e os drivers corretos (AMD, Intel ou NVIDIA). A detecção funciona
inclusive em máquinas mistas (ex.: CPU AMD + GPU NVIDIA).

Caso a detecção falhe ou você queira forçar manualmente, use as flags `--cpu` e `--gpu`:

```bash
./install.sh --cpu amd --gpu nvidia
```

| Flag    | Valores aceitos          |
| ------- | ------------------------ |
| `--cpu` | `amd`, `intel`           |
| `--gpu` | `amd`, `intel`, `nvidia` |

> As flags podem ser combinadas com as demais (`--plymouth`, `--gaming`). Rode
> `./install.sh --help` para ver todas as opções.

Se a GPU detectada (ou forçada) for **NVIDIA**, são necessários alguns passos manuais
adicionais para o Hyprland — veja [Configuração da GPU NVIDIA](#configuração-da-gpu-nvidia-hyprland).

### Modo Gaming

Por padrão, o `install.sh` instala um conjunto de apps de **produtividade**
(Obsidian, Xournal++, Zathura, OCR/Tesseract, etc.). Para uma máquina dedicada a
**jogos**, use a flag `--gaming`:

```bash
./install.sh --gaming
```

O que muda no modo gaming:

- **Remove** os apps de produtividade citados acima (não são instalados).
- **Adiciona** a stack de jogos: `steam` (+ `steam-native-runtime`), `gamemode`,
  `mangohud`, `lutris`, `heroic-games-launcher`, `prismlauncher` (Minecraft),
  `gamescope`, `vkbasalt`, `goverlay`, `protonplus` (gerenciador do Proton-GE) e
  suporte a controles (`xpadneo-dkms`, `game-devices-udev`).
- O usuário é adicionado ao grupo `gamemode` automaticamente.
- Adiciona o repositório do **CachyOS** e, a partir dele, instala:
  - o kernel otimizado **`linux-cachyos`** (+ headers) — o `linux-lts` é mantido como
    fallback. O GRUB é regenerado, mas tornar o CachyOS o kernel **padrão** de boot é
    um passo manual — veja [Definir o kernel CachyOS como padrão](#definir-o-kernel-cachyos-como-padrão-grub).
  - a sessão **`gamescope-session-cachyos`** (Steam Big Picture estilo Steam Deck) —
    veja [Modo Steam](#modo-steam-sessão-gamescope).

> O kernel e a sessão Steam só são instalados se o repositório do CachyOS for
> adicionado com sucesso (precisa de conexão durante a instalação).

> O restante do ambiente (Hyprland, terminal, dev tools, navegador, Discord, áudio,
> etc.) é o mesmo nos dois modos. A flag pode ser combinada com `--gpu`, por exemplo:
> `./install.sh --gaming --gpu nvidia`.

---

## Instalações Opcionais

Você pode adicionar componentes extras ao seu sistema utilizando os comandos abaixo.

### SDDM

O gerenciador de login **SDDM** é instalado e ativado **por padrão** pelo `install.sh`
(não há mais flag `--sddm`). Ele é o que permite escolher a sessão no login (Hyprland,
e o modo Steam quando em `--gaming`).

**Configuração do Tema (Astronaut Theme):**
Após a instalação, configure o tema seguindo os passos manuais abaixo:

1. Clone o repositório do tema diretamente para o diretório de temas do SDDM:

```bash
sudo git clone -b master --depth 1 https://github.com/PedroNeto05/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
```

1. Copie as fontes incluídas no tema para o diretório de fontes do seu sistema:

```bash
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
```

1. Configure o SDDM para utilizar o novo tema. Edite ou crie o arquivo `/etc/sddm.conf` e adicione as seguintes linhas:

```text
[Theme]
Current=sddm-astronaut-theme
```

1. Para habilitar o teclado virtual na tela de login, edite ou crie o arquivo `/etc/sddm.conf.d/virtualkbd.conf` com o seguinte conteúdo:

```text
[General]
InputMethod=qtvirtualkeyboard
```

### Instalação do Plymouth

Se desejar instalar o Plymouth para personalizar a tela de carregamento de boot, execute o comando abaixo e siga as instruções apresentadas:

```bash
./install.sh --plymouth
```

**Atenção:** Para que a animação do Plymouth funcione corretamente durante o boot, você precisa realizar duas configurações manuais no sistema:

#### 1. Adicionar o hook no `mkinitcpio.conf`

Edite o arquivo `/etc/mkinitcpio.conf` e adicione `plymouth` à linha dos `HOOKS`, preferencialmente logo após o `udev`. A linha deve ficar parecida com isto:

```text
HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap consolefont block filesystems fsck)
```

Após salvar o arquivo, é necessário regenerar a imagem do initramfs executando:

```bash
plymouth-set-default-theme -R green_blocks
```

#### 2. Adicionar opções de arranque do kernel

É obrigatório adicionar as opções `quiet` e `splash` aos parâmetros de inicialização do seu gerenciador de boot.

**Exemplo de configuração no rEFInd:**
Abra o arquivo de configuração de parâmetros do rEFInd, que geralmente fica localizado em `/boot/refind_linux.conf`.

Adicione `quiet splash` no final das opções de inicialização padrão. O arquivo editado deve ficar parecido com isto:

```text
"Boot with standard options"  "rw root=UUID=xxxx-xxxx-xxxx-xxxx quiet splash"
"Boot to single-user mode"    "rw root=UUID=xxxx-xxxx-xxxx-xxxx single"
"Boot with minimal options"   "ro root=UUID=xxxx-xxxx-xxxx-xxxx"
```

**Exemplo de configuração no GRUB:**

Abra o arquivo de configuração do GRUB, que geralmente fica localizado em `/etc/default/grub`.

Adicione `quiet splash` ao parâmetro `GRUB_CMDLINE_LINUX_DEFAULT`. O arquivo editado deve ficar parecido com isto:

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
```

Caso já existam outras opções configuradas, apenas acrescente `quiet splash` ao final:

```text
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash"
```

Após salvar o arquivo, atualize a configuração do GRUB executando:

```bash
sudo update-grub
```

Em algumas distribuições (como Arch Linux), utilize:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Estilização do rEFInd

**Nota:** Os passos abaixo pressupõem que você já possua o rEFInd instalado no seu sistema (seja através do `archinstall` ou via `pacman`). Aqui faremos apenas a estilização visual do gerenciador de boot.

**Configuração do Tema (Tokyo Night):**
Para aplicar o tema personalizado, siga os passos abaixo:

1. Crie o diretório de temas do rEFInd, caso ele ainda não exista:

```bash
sudo mkdir -p /boot/EFI/refind/themes
```

1. Clone o repositório do tema Tokyo Night dentro do diretório criado:

```bash
sudo git clone https://github.com/PedroNeto05/rEFInd-tokyo-night.git /boot/EFI/refind/themes/rEFInd-tokyo-night
```

1. Edite o arquivo principal de configuração do rEFInd (geralmente localizado em `/boot/EFI/refind/refind.conf` ou `/boot/EFI/refind.conf`) e adicione a seguinte linha no final do arquivo para ativar o tema:

```text
include themes/rEFInd-tokyo-night/theme.conf
```

#### Configurações Recomendadas

Para garantir o melhor visual e funcionamento do rEFInd, recomenda-se fazer as seguintes modificações no seu arquivo de configuração do rEFInd:

```text
timeout 10
use_graphics_for linux
dont_scan_dirs /EFI/Boot /EFI/BOOT
dont_scan_files bootx64.efi
default_selection vmlinuz-linux
hideui label, arrows, hints, editor
```

### Estilização do GTK

Escolha o tema e fonte no GTK settings (jetbrainsNerd Mono Bold 11)

### Estilização do QT

instale o tema no Kvantum Manager esta localizado em ~/.theme

Troque o tema para Kvantum em qt5 e qt6 settings e escolha a fonte (jetbrainsNerd Mono Bold 11)

---

## Configurações Manuais por Hardware

Estas configurações dependem do hardware específico da máquina e **não são feitas
automaticamente** pelos scripts (para não afetar máquinas com hardware diferente que
usam este mesmo repositório). Aplique-as apenas na máquina correspondente.

### Configuração da GPU NVIDIA (Hyprland)

Os pacotes da NVIDIA (`nvidia-dkms`, `nvidia-utils`, `lib32-nvidia-utils`,
`nvidia-settings`, `egl-wayland`) já são instalados automaticamente quando uma GPU
NVIDIA é detectada (ou ao usar `--gpu nvidia`). Após a instalação, faça o seguinte:

#### 1. Carregar os módulos da NVIDIA no initramfs

Edite `/etc/mkinitcpio.conf` e adicione os módulos da NVIDIA à linha `MODULES`:

```text
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

Em seguida, regenere o initramfs:

```bash
sudo mkinitcpio -P
```

#### 2. Ativar o modeset (DRM)

Os drivers recentes já habilitam o modeset por padrão. Para garantir, crie o arquivo
`/etc/modprobe.d/nvidia.conf` com:

```text
options nvidia_drm modeset=1
```

#### 3. Variáveis de ambiente do Hyprland

Adicione as variáveis abaixo ao `~/.config/hypr/environment.conf` **apenas nesta
máquina**:

```text
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
```

> ⚠️ O `environment.conf` é compartilhado via stow/git. Não comite essas linhas no
> ramo usado por máquinas que **não** são NVIDIA, ou mantenha-as em um ramo específico
> da máquina de gaming, para não quebrar as máquinas AMD/Intel.

Reinicie a sessão do Hyprland após aplicar. Mais detalhes na
[wiki do Hyprland sobre NVIDIA](https://wiki.hypr.land/Nvidia/).

### Overclock / Undervolt da GPU AMD (CoreCtrl)

O `corectrl` já é instalado e configurado (regra polkit + autostart). Por padrão, porém,
ele apenas **monitora** a GPU. Para que ele possa **controlar** clocks, curva de
ventoinha e undervolt, é preciso liberar o recurso *Overdrive* do driver `amdgpu`
adicionando um parâmetro ao kernel:

```text
amdgpu.ppfeaturemask=0xffffffff
```

Adicione esse parâmetro à linha de comando do kernel conforme o seu bootloader:

- **GRUB:** edite `GRUB_CMDLINE_LINUX_DEFAULT` em `/etc/default/grub` e regenere com
  `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
- **UKI / mkinitcpio:** edite `/etc/kernel/cmdline` e regenere com `sudo mkinitcpio -P`.

> Habilitar a máscara não altera nada sozinho — apenas destrava os ajustes no CoreCtrl.
> Use overclock/undervolt com moderação (ajustes agressivos podem travar a tela).

### Definir o kernel CachyOS como padrão (GRUB)

No modo `--gaming`, o kernel `linux-cachyos` é instalado e o GRUB é regenerado, mas o
sistema **continua iniciando pelo kernel anterior** (`linux-lts`) por padrão. O
`linux-lts` é mantido de propósito como fallback. Para tornar o CachyOS o padrão:

1. Edite `/etc/default/grub` e ajuste estas linhas (para o GRUB lembrar a última
   escolha do menu):

   ```text
   GRUB_DEFAULT=saved
   GRUB_SAVEDEFAULT=true
   ```

2. Regenere a configuração do GRUB:

   ```bash
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```

3. Reinicie e, no menu do GRUB, escolha a entrada do **CachyOS** uma vez. A partir daí
   ela será lembrada como padrão.

> Se algum dia o CachyOS apresentar problemas (kernels de ponta podem regredir),
> basta escolher o `linux-lts` no menu do GRUB para voltar a um boot estável.

### Modo Steam (sessão gamescope)

No modo `--gaming` é instalada a sessão **`gamescope-session-cachyos`** — o "Big
Picture" estilo Steam Deck (Gaming Mode) baseada na do SteamOS. Ela funciona em
paralelo ao Hyprland.

**Pré-requisito:** um display manager para escolher a sessão no login. O **SDDM** já é
instalado e ativado por padrão (veja [SDDM](#sddm)), então isso já está coberto.

**Como usar:**

- **Escolher no login:** na tela do SDDM, selecione entre **Hyprland** e a sessão
  **gamescope** (Steam) antes de entrar.
- **Sair do Steam para o desktop:** dentro do Steam (Gaming Mode), use o menu de
  energia → *Switch to Desktop*. Isso chama o `steamos-session-select`, que volta para
  a sessão de desktop.

> Observação: o `steamos-session-select` alterna para a sessão "desktop" configurada
> (padrão do SteamOS é o Plasma). Para que o "Switch to Desktop" volte ao **Hyprland**,
> pode ser necessário ajustar a sessão desktop alvo. A paridade total com o Steam Deck
> (retorno automático ao Gaming Mode, autologin) depende de configuração adicional e
> não é coberta automaticamente.
