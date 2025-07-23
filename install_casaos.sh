#!/bin/bash

# Script de Instalação do CasaOS para Raspberry Pi OS 64-bit
# Compatível com ARM64

set -e

echo "============================================================="
echo "=== INSTALAÇÃO DO CASAOS PARA RASPBERRY PI ==="
echo "============================================================="
echo ""

# 1. Atualizar o sistema
echo "1. Atualizando o sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Instalar dependências básicas
echo ""
echo "2. Instalando dependências..."
sudo apt install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

# 3. Instalar Docker (pré-requisito para CasaOS)
echo ""
echo "3. Instalando Docker..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 4. Instalar Docker Compose
echo ""
echo "4. Instalando Docker Compose..."
sudo apt install -y docker-compose-plugin

# 5. Habilitar Docker na inicialização
echo ""
echo "5. Habilitando Docker na inicialização..."
sudo systemctl enable docker
sudo systemctl start docker

# 6. Baixar e instalar CasaOS
echo ""
echo "6. Baixando e instalando CasaOS..."
curl -fsSL https://get.casaos.io | sudo bash

# 7. Verificar se Docker está rodando
echo ""
echo "7. Verificando Docker..."
sudo systemctl status docker --no-pager --lines=3

# 8. Verificar se CasaOS está rodando
echo ""
echo "8. Verificando CasaOS..."
sudo systemctl status casaos --no-pager --lines=3

# 9. Configurar firewall (se UFW estiver instalado)
echo ""
echo "9. Configurando firewall..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 80/tcp     # Interface web CasaOS
    sudo ufw allow 443/tcp    # HTTPS
    sudo ufw allow 22/tcp     # SSH
    echo "Portas liberadas no UFW"
else
    echo "UFW não instalado, pulando configuração de firewall"
fi

# 10. Descobrir IP do Raspberry Pi
echo ""
echo "10. Descobrindo IP do sistema..."
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# 11. Aguardar inicialização do CasaOS
echo ""
echo "11. Aguardando inicialização do CasaOS (30 segundos)..."
sleep 30

echo ""
echo "============================================================="
echo "✅ CASAOS INSTALADO COM SUCESSO!"
echo "============================================================="
echo ""
echo "🌐 **ACESSE O CASAOS EM:**"
echo "   http://${IP_ADDRESS}"
echo "   ou"
echo "   http://${IP_ADDRESS}:80"
echo ""
echo "🔐 **PRIMEIRO ACESSO:**"
echo "   1. Crie sua conta de administrador"
echo "   2. Configure senha segura"
echo "   3. Personalize as configurações iniciais"
echo ""
echo "📱 **RECURSOS DISPONÍVEIS:**"
echo "   ✅ App Store integrado"
echo "   ✅ Gerenciador de arquivos web"
echo "   ✅ Interface Docker visual"
echo "   ✅ Automação residencial"
echo "   ✅ Sincronização de dados"
echo "   ✅ Media server integrado"
echo ""
echo "🛠️ **COMANDOS ÚTEIS:**"
echo "   sudo systemctl status casaos    # Status do CasaOS"
echo "   sudo systemctl restart casaos   # Reiniciar CasaOS"
echo "   docker ps                       # Ver containers rodando"
echo "   casaos-cli                      # CLI do CasaOS"
echo ""
echo "🎯 **PRÓXIMOS PASSOS:**"
echo "   1. Acesse a interface web"
echo "   2. Configure sua conta"
echo "   3. Explore o App Store"
echo "   4. Instale aplicações desejadas"
echo "   5. Configure automação residencial"
echo ""
echo "============================================================="
echo "🏠 SEU SERVIDOR DOMÉSTICO ESTÁ PRONTO!"
echo "============================================================="
