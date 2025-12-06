#!/bin/bash

# Colores para la terminal
NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

# 1. Detener todos los contenedores en ejecución
echo -e "\n${YELLOW}Deteniendo todos los contenedores...${NC}"
docker stop $(docker ps -aq)  # Detiene todos los contenedores

# 2. Eliminar todos los contenedores
echo -e "${YELLOW}Eliminando todos los contenedores...${NC}"
docker rm $(docker ps -aq)  # Elimina todos los contenedores

# 3. Eliminar todas las imágenes de Docker
echo -e "${YELLOW}Eliminando todas las imágenes...${NC}"
docker rmi $(docker images -q)  # Elimina todas las imágenes

# 4. Eliminar todos los volúmenes
echo -e "${YELLOW}Eliminando todos los volúmenes...${NC}"
docker volume rm $(docker volume ls -q)  # Elimina todos los volúmenes

# 5. Eliminar todas las redes no utilizadas
echo -e "${YELLOW}Eliminando todas las redes no utilizadas...${NC}"
docker network prune -f  # Elimina redes no utilizadas

# 6. Limpiar imágenes, contenedores, volúmenes y redes no utilizados
echo -e "${YELLOW}Limpiando objetos no utilizados...${NC}"
docker system prune -af  # Elimina contenedores, imágenes y volúmenes no utilizados

# 7. Confirmación
echo -e "${GREEN}Limpieza completa. Todos los contenedores, imágenes y volúmenes han sido eliminados.${NC}"
