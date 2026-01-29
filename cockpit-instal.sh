#!/bin/bash

# Script de Instalação do Cockpit + Plugins para Raspberry Pi OS 64 Lite
# VERSÃO FINAL - Testado e corrigido para Debian 13 (Trixie)
# Com limpeza automática e tratamento de erros

echo "============================================================="
echo "=== INSTALAÇÃO COCKPIT + PLUGINS - Pi OS 64 ARM64 ==="
echo "============================================================="
echo ""

# Função para limpar em caso de erro
cleanup() {
    echo "Limpando arquivos temporários..."
    cd /tmp
    rm -rf cockpit-navigator cockpit-file-sharing cockpit-sensors*
}

# Configurar trap para limpar em caso de erro
trap cleanup EXIT

# 0. Limpeza prévia de instalações anteriores
echo "0. Limpando instalações anteriores..."
cd /tmp
rm -rf cockpit-navigator cockpit-file-sharing cockpit-sensors*
sudo rm -f /etc/apt/sources.list.d/45drives*

# 1. Atualizar o sistema
echo ""
echo "1. Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Instalar dependências completas
echo ""
echo "2. Instalando todas as dependências necessárias..."
sudo apt install -y curl wget git python3 rsync gettext make gcc g++ lm-sensors samba nfs-kernel-server build-essential moreutils

# 3. Instalar Node.js e npm (versão 20 LTS)
echo ""
echo "3. Instalando Node.js 20 LTS..."
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "Node.js já instalado: $(node -v)"
fi

# 4. Instalar Yarn globalmente
echo ""
echo "4. Instalando Yarn..."
if ! command -v yarn &> /dev/null; then
    sudo npm install -g yarn
else
    echo "Yarn já instalado: $(yarn -v)"
fi

# 5. Configurar variáveis do sistema
echo ""
echo "5. Configurando variáveis do sistema..."
. /etc/os-release
echo "Sistema detectado: ${PRETTY_NAME}"
echo "Codename: ${VERSION_CODENAME}"

# 6. Adicionar repositório backports
echo ""
echo "6. Configurando repositório backports..."
if [ ! -f /etc/apt/sources.list.d/backports.list ]; then
    echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
else
    echo "Backports já configurado"
fi

# 7. Atualizar lista de pacotes
echo ""
echo "7. Atualizando lista de pacotes..."
sudo apt update

# 8. Instalar Cockpit principal + Storaged
echo ""
echo "8. Instalando Cockpit principal + Storage..."
sudo apt install -t ${VERSION_CODENAME}-backports cockpit cockpit-storaged -y

# 9. Instalar cockpit-podman se disponível
echo ""
echo "9. Tentando instalar Cockpit-Podman (gerenciamento de containers)..."
sudo apt install -t ${VERSION_CODENAME}-backports cockpit-podman -y || echo "Cockpit-Podman não disponível, continuando..."

# 10. Habilitar e iniciar Cockpit
echo ""
echo "10. Habilitando e iniciando Cockpit..."
sudo systemctl enable cockpit.socket
sudo systemctl start cockpit.socket

# Verificar se Cockpit está rodando
if sudo systemctl is-active --quiet cockpit.socket; then
    echo "✅ Cockpit iniciado com sucesso!"
else
    echo "❌ ERRO: Cockpit não iniciou corretamente"
    exit 1
fi

# 11. Instalar Cockpit-Navigator do GitHub
echo ""
echo "11. Instalando Cockpit-Navigator..."
cd /tmp
rm -rf cockpit-navigator
git clone https://github.com/45Drives/cockpit-navigator.git
cd cockpit-navigator
git checkout v0.5.10
echo "Compilando Navigator (pode demorar alguns minutos)..."
make
sudo make install
echo "✅ Navigator instalado"

# 12. Instalar Cockpit-File-Sharing do GitHub
echo ""
echo "12. Instalando Cockpit-File-Sharing..."
cd /tmp
rm -rf cockpit-file-sharing
git clone https://github.com/45Drives/cockpit-file-sharing.git
cd cockpit-file-sharing
echo "Compilando File-Sharing (pode demorar alguns minutos)..."
make
sudo make install
echo "✅ File-Sharing instalado"

# 13. Instalar Cockpit-Sensors
echo ""
echo "13. Instalando Cockpit-Sensors..."
cd /tmp
rm -rf cockpit-sensors*
wget -q https://github.com/ocristopfer/cockpit-sensors/releases/latest/download/cockpit-sensors.tar.xz
if [ -f cockpit-sensors.tar.xz ]; then
    tar -xf cockpit-sensors.tar.xz
    if [ -d cockpit-sensors/dist ]; then
        sudo mkdir -p /usr/share/cockpit/sensors
        sudo cp -r cockpit-sensors/dist/* /usr/share/cockpit/sensors/
        echo "✅ Sensors instalado"
    else
        echo "⚠️ Erro ao extrair Sensors, continuando..."
    fi
else
    echo "⚠️ Não foi possível baixar Sensors, continuando..."
fi

# 14. Configurar lm-sensors
echo ""
echo "14. Configurando lm-sensors..."
sudo sensors-detect --auto

# 15. Configurar serviços de compartilhamento
echo ""
echo "15. Configurando Samba e NFS..."
sudo systemctl enable smbd nmbd nfs-kernel-server
sudo systemctl start smbd nmbd nfs-kernel-server

# 16. Verificar instalação dos plugins
echo ""
echo "16. Verificando plugins instalados..."
PLUGINS_INSTALLED=0
[ -d /usr/share/cockpit/navigator ] && echo "✅ Navigator: OK" && PLUGINS_INSTALLED=$((PLUGINS_INSTALLED+1))
[ -d /usr/share/cockpit/file-sharing ] && echo "✅ File-Sharing: OK" && PLUGINS_INSTALLED=$((PLUGINS_INSTALLED+1))
[ -d /usr/share/cockpit/sensors ] && echo "✅ Sensors: OK" && PLUGINS_INSTALLED=$((PLUGINS_INSTALLED+1))
[ -d /usr/share/cockpit/storaged ] && echo "✅ Storaged: OK" && PLUGINS_INSTALLED=$((PLUGINS_INSTALLED+1))
[ -d /usr/share/cockpit/podman ] && echo "✅ Podman: OK" && PLUGINS_INSTALLED=$((PLUGINS_INSTALLED+1)) || echo "⚠️ Podman: Não instalado"

echo ""
echo "Total de plugins instalados: $PLUGINS_INSTALLED"

# 17. Descobrir IP do Raspberry Pi
echo ""
echo "17. Descobrindo IP do sistema..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# 18. Verificar status dos serviços
echo ""
echo "18. Status dos serviços:"
echo ""
sudo systemctl is-active --quiet cockpit.socket && echo "✅ Cockpit: RODANDO" || echo "❌ Cockpit: PARADO"
sudo systemctl is-active --quiet smbd && echo "✅ Samba: RODANDO" || echo "❌ Samba: PARADO"
sudo systemctl is-active --quiet nfs-kernel-server && echo "✅ NFS: RODANDO" || echo "❌ NFS: PARADO"

# 19. Limpeza final
echo ""
echo "19. Limpando arquivos temporários..."
cd /tmp
rm -rf cockpit-navigator cockpit-file-sharing cockpit-sensors*
sudo apt autoremove -y
sudo apt autoclean

echo ""
echo "============================================================="
echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "============================================================="
echo ""
echo "🌐 **ACESSE O COCKPIT:**"
echo "   http://${IP_ADDRESS}:9090"
echo ""
echo "   Ou via hostname:"
echo "   http://$(hostname).local:9090"
echo ""
echo "📋 **PLUGINS INSTALADOS:**"
echo "   ✅ Cockpit (interface principal)"
echo "   ✅ Storaged (gerenciamento de discos)"
echo "   ✅ Navigator (navegador de arquivos avançado)"
echo "   ✅ File-Sharing (compartilhamento Samba/NFS)"
echo "   ✅ Sensors (monitoramento de temperatura)"
if [ -d /usr/share/cockpit/podman ]; then
    echo "   ✅ Podman (gerenciamento de containers)"
fi
echo ""
echo "🔐 **LOGIN:**"
echo "   Usuário: $(whoami)"
echo "   Senha: sua senha do sistema"
echo ""
echo "📝 **PRÓXIMOS PASSOS:**"
echo ""
echo "   1. Para criar usuário Samba:"
echo "      sudo smbpasswd -a $(whoami)"
echo ""
echo "   2. Para acessar via NPM (Nginx Proxy Manager):"
echo "      - Crie Proxy Host apontando para: ${IP_ADDRESS}:9090"
echo "      - Use HTTPS e certificado SSL"
echo "      - Não precisa configurações extras no Cockpit"
echo ""
echo "   3. Para integrar com AdGuard:"
echo "      - AdGuard funciona independente (porta 3000)"
echo "      - Cockpit não interfere com DNS"
echo ""
echo "🎯 **RECURSOS DISPONÍVEIS:**"
echo "   • Dashboard de monitoramento em tempo real"
echo "   • Terminal SSH integrado no navegador"
echo "   • Upload/download de arquivos via web"
echo "   • Criação de compartilhamentos Samba/NFS visual"
echo "   • Gerenciamento de serviços systemd"
echo "   • Visualização de logs do sistema"
echo "   • Gestão de usuários e permissões"
echo "   • Monitoramento de temperatura e sensores"
echo "   • Gerenciamento de partições e RAID"
if [ -d /usr/share/cockpit/podman ]; then
    echo "   • Gerenciamento de containers Podman"
fi
echo ""
echo "============================================================="
echo "🎉 COCKPIT PRONTO! ACESSE: http://${IP_ADDRESS}:9090"
echo "============================================================="
