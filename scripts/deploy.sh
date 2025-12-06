#!/bin/bash

# Variables
COMPOSE_FILE="../docker/docker-compose.yml"  # Ruta al archivo docker-compose.yml
INIT_SQL_FILE="../sql/init.sql"  # Ruta al archivo init.sql

# Colores para la terminal
NC='\033[0m' # No Color
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

# 1. Levantar contenedores con Docker Compose
echo -e "\n${CYAN}Iniciando los contenedores con Docker Compose...${NC}"
docker compose -f $COMPOSE_FILE up -d

# Esperar un momento para que los contenedores se inicien
echo -e "${YELLOW}Esperando que los contenedores se inicien...${NC}"
sleep 30

# 2. Obtener la IP del Master
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql1)

# 3. Configuración del Master
echo -e "${CYAN}Configurando el Master...${NC}"
docker exec -it mysql1 bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it mysql1 bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker exec -it mysql1 bash -c "echo 'server-id=1' >> /etc/mysql/my.cnf"
docker restart mysql1

# Configuración MySQL
docker exec -it mysql1 mysql -u root -proot -e "
SET GLOBAL server_id = 1;
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%' IDENTIFIED BY 'root';
SHOW MASTER STATUS;
"

# 4. Configuración de los Slaves (mysql2 y mysql3)
for SLAVE in mysql2 mysql3; do
  echo -e "${CYAN}Configurando $SLAVE...${NC}"
  docker exec -it $SLAVE bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'server-id=2' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'relay-log=mysql-relay-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'read-only=1' >> /etc/mysql/my.cnf"
  docker restart $SLAVE

  # Conectar al Master
  docker exec -it $SLAVE mysql -u root -proot -e "
  CHANGE MASTER TO
      MASTER_HOST = '$MASTER_IP',
      MASTER_USER = 'replica',
      MASTER_PASSWORD = 'root',
      MASTER_LOG_FILE = 'mysql-bin.000001',
      MASTER_LOG_POS = 154;
  START SLAVE;
  "
done

# 5. Verificar la replicación
echo -e "${CYAN}Verificando el estado de la replicación en los Slaves...${NC}"
docker exec -it mysql2 mysql -u root -proot -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"
docker exec -it mysql3 mysql -u root -proot -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"

# 6. Insertar base de datos usando init.sql
if [ -f "$INIT_SQL_FILE" ]; then
    echo -e "${GREEN}Ejecutando archivo init.sql para insertar la base de datos...${NC}"
    docker exec -i mysql1 mysql -u root -proot < $INIT_SQL_FILE
else
    echo -e "${RED}No se encontró el archivo init.sql.${NC}"
fi

# 7. Verificar la replicación de datos
echo -e "${CYAN}Verificando que los datos se replican en los Slaves...${NC}"
docker exec -it mysql2 mysql -u root -proot -e "SHOW DATABASES;"
docker exec -it mysql3 mysql -u root -proot -e "SHOW DATABASES;"

echo -e "${GREEN}Configuración de la replicación MySQL completada.${NC}"
