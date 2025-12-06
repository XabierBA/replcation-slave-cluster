#!/bin/bash

# Colores para la terminal
NC='\033[0m'  # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'

# Función para imprimir títulos
print_title() {
    echo -e "\n${CYAN}### $1 ###${NC}\n"
}

# 1. Detener todos los contenedores en ejecución
print_title "Deteniendo todos los contenedores..."
echo -e "${YELLOW}Deteniendo todos los contenedores en ejecución...${NC}"
docker stop $(docker ps -aq)  # Detiene todos los contenedores

# 2. Eliminar todos los contenedores
print_title "Eliminando todos los contenedores..."
echo -e "${YELLOW}Eliminando todos los contenedores...${NC}"
docker rm $(docker ps -aq)  # Elimina todos los contenedores

# 3. Eliminar todas las imágenes de Docker
print_title "Eliminando todas las imágenes..."
echo -e "${YELLOW}Eliminando todas las imágenes de Docker...${NC}"
docker rmi $(docker images -q)  # Elimina todas las imágenes

# 4. Eliminar todos los volúmenes
print_title "Eliminando todos los volúmenes..."
echo -e "${YELLOW}Eliminando todos los volúmenes de Docker...${NC}"
docker volume rm $(docker volume ls -q)  # Elimina todos los volúmenes

# 5. Eliminar todas las redes no utilizadas
print_title "Eliminando todas las redes no utilizadas..."
echo -e "${YELLOW}Eliminando redes no utilizadas...${NC}"
docker network prune -f  # Elimina redes no utilizadas

# 6. Limpiar imágenes, contenedores, volúmenes y redes no utilizados
print_title "Limpiando objetos no utilizados..."
echo -e "${YELLOW}Limpiando contenedores, imágenes y volúmenes no utilizados...${NC}"
docker system prune -af  # Elimina contenedores, imágenes y volúmenes no utilizados

# 7. Confirmación final
print_title "Limpieza completa"
echo -e "${GREEN}✔ Limpieza completa. Todos los contenedores, imágenes y volúmenes han sido eliminados.${NC}"

