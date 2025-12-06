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
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'

# Función para verificar si MySQL está listo en el contenedor
wait_for_mysql() {
    CONTAINER=$1
    echo -e "${MAGENTA}Esperando que MySQL esté listo en $CONTAINER...${NC}"
    until docker exec $CONTAINER mysqladmin ping -u root -p$MYSQL_PASSWORD --silent; do
        sleep 1
    done
    echo -e "${GREEN}✔ MySQL está listo en $CONTAINER.${NC}"
}

# 1. Levantar contenedores de MySQL
echo -e "\n${CYAN}Iniciando los contenedores MySQL...${NC}"
docker run --name $MASTER_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7
docker run --name $SLAVE1_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7
docker run --name $SLAVE2_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD -d mysql:5.7

# Esperar un momento para que los contenedores se inicien
echo -e "${YELLOW}🔄 Esperando que los contenedores se inicien...${NC}"
sleep 30  # Asegurarnos de que los contenedores se inicien correctamente

# 2. Esperar hasta que MySQL esté disponible
echo -e "${CYAN}Verificando que MySQL esté disponible en los contenedores...${NC}"
wait_for_mysql $MASTER_CONTAINER
wait_for_mysql $SLAVE1_CONTAINER
wait_for_mysql $SLAVE2_CONTAINER

# 3. Obtener la IP del contenedor Master
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $MASTER_CONTAINER)

echo -e "${BLUE}La IP del Master es: $MASTER_IP${NC}"

# 4. Configuración del Master
echo -e "\n${CYAN}Configurando el Master...${NC}"
docker exec -it $MASTER_CONTAINER bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'server-id=1' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'bind-address=0.0.0.0' >> /etc/mysql/my.cnf"  # Permitir conexiones externas
docker restart $MASTER_CONTAINER

# Esperar un poco después de reiniciar el contenedor master
echo -e "${YELLOW}⏳ Esperando que MySQL en $MASTER_CONTAINER se inicie después del reinicio...${NC}"
sleep 10  # Esperar un poco más para que MySQL se inicie

# Configuración MySQL en el master
echo -e "${BLUE}Configurando la replicación en el Master...${NC}"
docker exec -it $MASTER_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "
SET GLOBAL server_id = 1;
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%' IDENTIFIED BY 'root';
SHOW MASTER STATUS;
"

# 5. Configuración de los Slaves (mysql2 y mysql3)
for SLAVE in $SLAVE1_CONTAINER $SLAVE2_CONTAINER; do
  echo -e "\n${CYAN}Configurando $SLAVE...${NC}"
  docker exec -it $SLAVE bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'server-id=2' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'relay-log=mysql-relay-bin' >> /etc/mysql/my.cnf"
  docker exec -it $SLAVE bash -c "echo 'read-only=1' >> /etc/mysql/my.cnf"
  docker restart $SLAVE

  # Esperar un poco después de reiniciar los slaves
  echo -e "${YELLOW}⏳ Esperando que MySQL en $SLAVE se inicie después del reinicio...${NC}"
  sleep 10  # Esperar un poco más para que MySQL se inicie

  # Conectar al Master desde el Slave y configurar la replicación usando la IP del Master
  echo -e "${BLUE}Configurando la replicación en $SLAVE...${NC}"
  docker exec -it $SLAVE mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "
  CHANGE MASTER TO
      MASTER_HOST = '$MASTER_IP',  # Usar la IP del master obtenida
      MASTER_USER = 'replica',
      MASTER_PASSWORD = 'root',
      MASTER_LOG_FILE = 'mysql-bin.000001',
      MASTER_LOG_POS = 154;
  START SLAVE;
  "
done

# 6. Verificar el estado de la replicación
echo -e "\n${CYAN}Verificando el estado de la replicación en los Slaves...${NC}"
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"

# 7. Insertar base de datos usando init.sql
if [ -f "$INIT_SQL_FILE" ]; then
    echo -e "${GREEN}✔ Ejecutando archivo init.sql para insertar la base de datos...${NC}"
    docker exec -i $MASTER_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 < $INIT_SQL_FILE
else
    echo -e "${RED}❌ No se encontró el archivo init.sql.${NC}"
fi

# 8. Verificar la replicación de datos
echo -e "${CYAN}Verificando que los datos se replican en los Slaves...${NC}"
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW DATABASES;"
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_PASSWORD -h 127.0.0.1 -e "SHOW DATABASES;"

echo -e "\n${GREEN}✅ Configuración de la replicación MySQL completada.${NC}"
