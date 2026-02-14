# Instalação do Ambiente

Siga as instruções abaixo para configurar tudo corretamente.

## Instalação Principal

Primeiro, clone este repositório para a sua máquina:

```bash
git clone [https://github.com/PedroNeto05/.hyprconfig](https://github.com/PedroNeto05/.hyprconfig)
cd .hyprconfig
```

Após clonar o repositório, execute o script de pré-instalação para preparar o sistema e, em seguida, rode a instalação principal:

```bash
./pre-install.sh
./install.sh
```

---

## Instalações Opcionais

Você pode adicionar componentes extras ao seu sistema utilizando os comandos abaixo.

### Instalação do SDDM
Para instalar o gerenciador de login SDDM, rode o comando com a flag `--sddm` e siga os passos que aparecerão na tela:

```bash
./install.sh --sddm
```

**Configuração do Tema (Astronaut Theme):**
Após a instalação, configure o tema seguindo os passos manuais abaixo:

1. Clone o repositório do tema diretamente para o diretório de temas do SDDM:
```bash
sudo git clone -b master --depth 1 https://github.com/PedroNeto05/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme
```

2. Copie as fontes incluídas no tema para o diretório de fontes do seu sistema:
```bash
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
```

3. Configure o SDDM para utilizar o novo tema. Edite ou crie o arquivo `/etc/sddm.conf` e adicione as seguintes linhas:
```text
[Theme]
Current=sddm-astronaut-theme
```

4. Para habilitar o teclado virtual na tela de login, edite ou crie o arquivo `/etc/sddm.conf.d/virtualkbd.conf` com o seguinte conteúdo:
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
sudo mkinitcpio -P
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

### Instalação do rEFInd
Para configurar o gerenciador de boot rEFInd, utilize o comando a seguir e acompanhe os passos na tela:

```bash
./install.sh --refind
```
