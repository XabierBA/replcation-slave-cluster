#!/bin/bash

# Descripción del Proyecto
TITULO="Despliegue Máquina Virtual con Docker"
CURSO="Centros de Datos, 2025/26"
DIR_BASE_POR_DEFECTO=$HOME/CDA2526
URL_BASE="http://cda.drordas.info"  # No utilizado en este script actualizado
DIR_BASE=${DIR_BASE:-$DIR_BASE_POR_DEFECTO}
DIR_VARLIB=/var/lib/CDA2526

# Variables de la Máquina Virtual y Repositorio
VM_NAME="docker-vm"               # Nombre de la máquina virtual
VM_MEMORY="1024"                  # Memoria RAM (en MB)
VM_CPUS="2"                       # Número de CPUs
VM_VDI_PATH="$HOME/$VM_NAME.vdi"  # Ruta del archivo VDI
VM_OS="Ubuntu_64"                 # Sistema operativo base (Ubuntu 64-bit)
REPO_URL="https://github.com/XabierBA/replcation-slave-cluster.git"  # Repositorio GitHub
VM_IP="192.168.56.101"            # Dirección IP privada de la VM

# Colores para la terminal
NC='\033[0m'  # No Color
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'

# Función para crear la máquina virtual
crear_vm() {
    echo -e "${CYAN}Creando la máquina virtual $VM_NAME...${NC}"
    VBoxManage createvm --name $VM_NAME --register --ostype $VM_OS --basefolder $HOME/VirtualBox\ VMs
    VBoxManage modifyvm $VM_NAME --memory $VM_MEMORY --cpus $VM_CPUS --nic1 nat --nictype1 82540EM --cableconnected1 on --audio none

    # Crear disco duro virtual (VDI)
    echo -e "${YELLOW}Creando el disco duro virtual $VM_VDI_PATH...${NC}"
    VBoxManage createhd --filename $VM_VDI_PATH --size 10000 --format VDI  # 10 GB de espacio

    # Conectar el disco duro a la VM
    VBoxManage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_VDI_PATH
}

# Función para instalar Docker en la VM
instalar_docker() {
    echo -e "${CYAN}Instalando Docker en la VM...${NC}"
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "/usr/bin/apt-get" -- apt-get update -y
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "/usr/bin/apt-get" -- apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "curl" -- args -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "/usr/bin/apt-get" -- add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "/usr/bin/apt-get" -- apt-get update -y
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "/usr/bin/apt-get" -- apt-get install -y docker-ce

    # Verificar que Docker se ha instalado correctamente
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "docker" -- version
}

# Función para clonar el repositorio de GitHub
clonar_repositorio() {
    echo -e "${MAGENTA}Clonando el repositorio desde GitHub...${NC}"
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "git" -- args clone $REPO_URL /home/vagrant/replcation-slave-cluster

    # Verificar que el repositorio se ha clonado correctamente
    VBoxManage guestcontrol $VM_NAME run --username vagrant --password vagrant --exe "ls" -- args /home/vagrant/replcation-slave-cluster
}

# Función principal que ejecuta todo el flujo
main() {
    # Crear la máquina virtual
    crear_vm

    # Arrancar la VM
    echo -e "${CYAN}Iniciando la máquina virtual...${NC}"
    VBoxManage startvm $VM_NAME --type headless

    # Esperar un momento para asegurar que la VM arranque correctamente
    sleep 30

    # Instalar Docker en la VM
    instalar_docker

    # Clonar el repositorio
    clonar_repositorio

    echo -e "${GREEN}✅ El script ha finalizado con éxito.${NC} Docker ha sido instalado y el repositorio ha sido clonado."
}

# Llamada a la función principal
main
