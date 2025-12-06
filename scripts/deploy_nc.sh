#!/bin/bash

# Variables
MYSQL_PASSWORD="root"
INIT_SQL_FILE="../sql/init.sql"  # Ruta al archivo init.sql
MASTER_CONTAINER="mysql-master"
SLAVE1_CONTAINER="mysql-slave1"
SLAVE2_CONTAINER="mysql-slave2"

# Colores para la terminal
NC='\033[0m' # No Color
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

# 1. Levantar contenedores de MySQL
echo -e "\n${CYAN}Iniciando los contenedores MySQL...${NC}"
docker run --name $MASTER_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7
docker run --name $SLAVE1_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7
docker run --name $SLAVE2_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7

# Esperar un momento para que los contenedores se inicien
echo -e "${YELLOW}Esperando que los contenedores se inicien...${NC}"
sleep 30

# 2. Verificar si MySQL está listo en los contenedores
echo -e "${CYAN}Esperando a que MySQL esté listo en los contenedores...${NC}"

# Función para verificar si MySQL está listo en el contenedor
wait_for_mysql() {
    CONTAINER=$1
    until docker exec $CONTAINER mysqladmin ping -u root -p$MYSQL_PASSWORD --silent; do
        echo -e "${YELLOW}Esperando que MySQL esté listo en $CONTAINER...${NC}"
        sleep 1
    done
    echo -e "${GREEN}MySQL está listo en $CONTAINER.${NC}"
}

# Esperamos que MySQL esté listo en el master y los slaves
wait_for_mysql $MASTER_CONTAINER
wait_for_mysql $SLAVE1_CONTAINER
wait_for_mysql $SLAVE2_CONTAINER

# 3. Configuración del Master
echo -e "${CYAN}Configurando el Master...${NC}"
docker exec -it $MASTER_CONTAINER bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'server-id=1' >> /etc/mysql/my.cnf"
docker restart $MASTER_CONTAINER

# Configuración MySQL en el master
docker exec -it $MASTER_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "
SET GLOBAL server_id = 1;
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%' IDENTIFIED BY 'root';
SHOW MASTER STATUS;
"

# 4. Configuración de los Slaves (mysql2 y mysql3)
for SLAVE in $SLAVE1_CONTAINER $SLAVE2_CONTAINER; do
  echo -e "${CYAN}Configurando $SLAVE...${NC}"
  docker exec -it $SLAVE bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'server-id=2' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'relay-log=mysql-relay-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'read-only=1' >> /etc/mysql/my.cnf"
  docker restart $SLAVE

  # Conectar al Master desde el Slave y configurar la replicación
  docker exec -it $SLAVE mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "
  CHANGE MASTER TO
      MASTER_HOST = 'mysql-master',
      MASTER_USER = 'replica',
      MASTER_PASSWORD = 'root',
      MASTER_LOG_FILE = 'mysql-bin.000001',
      MASTER_LOG_POS = 154;
  START SLAVE;
  "
done

# 5. Verificar el estado de la replicación
echo -e "${CYAN}Verificando el estado de la replicación en los Slaves...${NC}"
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"

# 6. Insertar base de datos usando init.sql
if [ -f "$INIT_SQL_FILE" ]; then
    echo -e "${GREEN}Ejecutando archivo init.sql para insertar la base de datos...${NC}"
    docker exec -i $MASTER_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 < $INIT_SQL_FILE
else
    echo -e "${RED}No se encontró el archivo init.sql.${NC}"
fi

# 7. Verificar la replicación de datos
echo -e "${CYAN}Verificando que los datos se replican en los Slaves...${NC}"
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW DATABASES;"
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW DATABASES;"

echo -e "${GREEN}Configuración de la replicación MySQL completada.${NC}"
