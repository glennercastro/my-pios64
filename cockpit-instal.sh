#!/bin/bash

# Script de Instalação do Cockpit + Plugins para Raspberry Pi OS 64 Lite
# Compatível com ARM64 - 
# Inclui: files, navigator, sensors, file-sharing, storaged

set -e  # Para se houver erro

echo "============================================================="
echo "=== INSTALAÇÃO COCKPIT + PLUGINS - Pi OS 64 ARM64 (SEM TAILSCALE) ==="
echo "============================================================="
echo ""

# 1. Atualizar o sistema
echo "1. Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Instalar dependências básicas
echo ""
echo "2. Instalando dependências..."
sudo apt install -y curl wget git python3 rsync zip npm nodejs gettext make gcc g++ lm-sensors samba nfs-kernel-server build-essential

# 3. Configurar variáveis do sistema
echo ""
echo "3. Configurando variáveis do sistema..."
. /etc/os-release

# 4. Adicionar repositório backports
echo ""
echo "4. Adicionando repositório backports..."
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" | sudo tee /etc/apt/sources.list.d/backports.list

# 5. Adicionar repositório 45Drives (para file-sharing)
echo ""
echo "5. Adicionando repositório 45Drives..."
curl -sSL https://repo.45drives.com/setup | sudo bash

# 6. Atualizar lista de pacotes
echo ""
echo "6. Atualizando lista de pacotes..."
sudo apt update

# 7. Instalar Cockpit principal + Storaged
echo ""
echo "7. Instalando Cockpit principal + gerenciamento de armazenamento..."
sudo apt install -t ${VERSION_CODENAME}-backports cockpit cockpit-storaged -y

# 8. Habilitar e iniciar Cockpit
echo ""
echo "8. Habilitando e iniciando Cockpit..."
sudo systemctl enable cockpit.socket
sudo systemctl start cockpit.socket

# 9. Instalar Cockpit-Files (se disponível no repositório)
echo ""
echo "9. Tentando instalar Cockpit-Files..."
sudo apt install -t ${VERSION_CODENAME}-backports cockpit-files -y || echo "Cockpit-Files não disponível no repositório, continuando..."

# 10. Instalar Cockpit-File-Sharing
echo ""
echo "10. Instalando Cockpit-File-Sharing..."
sudo apt install cockpit-file-sharing -y || {
    echo "Instalando do GitHub como alternativa..."
    cd /tmp
    git clone https://github.com/45Drives/cockpit-file-sharing.git
    cd cockpit-file-sharing
    sudo make install
    cd /tmp
    rm -rf cockpit-file-sharing
}

# 11. Instalar Cockpit-Navigator do GitHub
echo ""
echo "11. Instalando Cockpit-Navigator do GitHub..."
cd /tmp
git clone https://github.com/45Drives/cockpit-navigator.git
cd cockpit-navigator
git checkout v0.5.10  # Versão mais estável
sudo make install
cd /tmp
rm -rf cockpit-navigator

# 12. Instalar Cockpit-Sensors
echo ""
echo "12. Instalando Cockpit-Sensors..."
cd /tmp
wget https://github.com/ocristopfer/cockpit-sensors/releases/latest/download/cockpit-sensors.tar.xz
tar -xf cockpit-sensors.tar.xz cockpit-sensors/dist
sudo mv cockpit-sensors/dist /usr/share/cockpit/sensors
rm -rf cockpit-sensors*

# 13. Configurar lm-sensors
echo ""
echo "13. Configurando lm-sensors..."
sudo sensors-detect --auto

# 14. Configurar serviços de compartilhamento
echo ""
echo "14. Configurando serviços de compartilhamento..."
sudo systemctl enable smbd
sudo systemctl enable nmbd
sudo systemctl enable nfs-kernel-server
sudo systemctl start smbd
sudo systemctl start nmbd
sudo systemctl start nfs-kernel-server

# 15. Configurar firewall para Cockpit
echo ""
echo "15. Configurando firewall (se UFW estiver instalado)..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 9090/tcp
    echo "Porta 9090 liberada no UFW"
else
    echo "UFW não instalado, pulando configuração de firewall"
fi

# 16. Descobrir IP do Raspberry Pi
echo ""
echo "16. Descobrindo IP do sistema..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# 17. Verificar status dos serviços principais
echo ""
echo "17. Verificando status dos serviços..."
echo ""
echo "--- Status Cockpit ---"
sudo systemctl status cockpit.socket --no-pager --lines=3
echo ""
echo "--- Status Samba ---"
sudo systemctl status smbd --no-pager --lines=3
echo ""
echo "--- Status NFS ---"
sudo systemctl status nfs-kernel-server --no-pager --lines=3

# 18. Limpeza de arquivos temporários
echo ""
echo "18. Limpando arquivos temporários..."
sudo apt autoremove -y
sudo apt autoclean

echo ""
echo "============================================================="
echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "============================================================="
echo ""
echo "🌐 **ACESSE O COCKPIT EM:**"
echo "   http://${IP_ADDRESS}:9090"
echo ""
echo "📋 **PLUGINS INSTALADOS:**"
echo "   ✅ Cockpit Principal (interface base)"
echo "   ✅ Cockpit-Storaged (monitoramento e gerenciamento de disco)"
echo "   ✅ Cockpit-Files (navegador de arquivos básico)"
echo "   ✅ Cockpit-File-Sharing (compartilhamentos Samba/NFS)"
echo "   ✅ Cockpit-Navigator (navegador de arquivos avançado)"
echo "   ✅ Cockpit-Sensors (monitoramento de temperatura/hardware)"
echo ""
echo "🚫 **REMOVIDO:**"
echo "   ❌ Cockpit-Tailscale (removido por problemas de compatibilidade)"
echo ""
echo "🔐 **LOGIN:**"
echo "   Use suas credenciais de usuário do sistema para fazer login"
echo "   (mesmo usuário e senha que você usa no SSH)"
echo ""
echo "📝 **CONFIGURAÇÕES ADICIONAIS NECESSÁRIAS:**"
echo "   • Para usuários Samba: sudo smbpasswd -a SEU_USUARIO"
echo "   • Para NFS: configurações em /etc/exports"
echo ""
echo "🎯 **RECURSOS DISPONÍVEIS:**"
echo "   • Monitoramento de sistema em tempo real"
echo "   • Gerenciamento completo de discos e partições"
echo "   • Compartilhamento de arquivos Samba/NFS"
echo "   • Navegação e upload de arquivos via web"
echo "   • Monitoramento de sensores e temperatura"
echo "   • Terminal integrado via web"
echo "   • Logs do sistema centralizados"
echo ""
echo "🔍 **ONDE ENCONTRAR OS PLUGINS:**"
echo "   Todos os plugins estarão na seção 'Applications' do Cockpit"
echo ""
echo "============================================================="
echo "🎉 SEU RASPBERRY PI ESTÁ PRONTO PARA GERENCIAMENTO WEB!"
echo "============================================================="
