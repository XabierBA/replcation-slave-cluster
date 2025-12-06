#!/bin/bash

# Variables
MASTER_CONTAINER="mysql-master"
SLAVE1_CONTAINER="mysql-slave1"
SLAVE2_CONTAINER="mysql-slave2"
MYSQL_ROOT_PASSWORD="root"
REPLICA_USER="replica_user"
REPLICA_PASSWORD="password"
INIT_SQL_FILE="./init.sql"

# 1. Crear contenedores
echo "Creando contenedores MySQL..."
docker run --name $MASTER_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d mysql:5.7
docker run --name $SLAVE1_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d mysql:5.7
docker run --name $SLAVE2_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d mysql:5.7

# Esperar a que los contenedores se inicien completamente
echo "Esperando a que los contenedores se inicien..."
sleep 30

# 2. Configuración del Master
echo "Configurando el Master..."
docker exec -it $MASTER_CONTAINER bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker exec -it $MASTER_CONTAINER bash -c "echo 'server-id=1' >> /etc/mysql/my.cnf"
docker restart $MASTER_CONTAINER

# Esperar el reinicio del contenedor master
sleep 10

# Acceder al cliente MySQL y ejecutar los comandos para configurar el Master
docker exec -it $MASTER_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "
SET GLOBAL server_id = 1;
GRANT REPLICATION SLAVE ON *.* TO '$REPLICA_USER'@'%' IDENTIFIED BY '$REPLICA_PASSWORD';
SHOW MASTER STATUS;
"

# Obtener la IP del Master
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $MASTER_CONTAINER)
MASTER_LOG_FILE=$(docker exec -it $MASTER_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW MASTER STATUS;" | grep mysql-bin | awk '{print $1}')
MASTER_LOG_POS=$(docker exec -it $MASTER_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW MASTER STATUS;" | grep mysql-bin | awk '{print $2}')

# 3. Configuración del Slave1
echo "Configurando el Slave1..."
docker exec -it $SLAVE1_CONTAINER bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it $SLAVE1_CONTAINER bash -c "echo 'server-id=2' >> /etc/mysql/my.cnf"
docker exec -it $SLAVE1_CONTAINER bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker restart $SLAVE1_CONTAINER

# Configurar el Slave1 para que se conecte al Master
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "
CHANGE MASTER TO
    MASTER_HOST = '$MASTER_IP',
    MASTER_USER = '$REPLICA_USER',
    MASTER_PASSWORD = '$REPLICA_PASSWORD',
    MASTER_LOG_FILE = '$MASTER_LOG_FILE',
    MASTER_LOG_POS = $MASTER_LOG_POS;
START SLAVE;
"

# 4. Configuración del Slave2
echo "Configurando el Slave2..."
docker exec -it $SLAVE2_CONTAINER bash -c "echo '[mysqld]' >> /etc/mysql/my.cnf"
docker exec -it $SLAVE2_CONTAINER bash -c "echo 'server-id=3' >> /etc/mysql/my.cnf"
docker exec -it $SLAVE2_CONTAINER bash -c "echo 'log-bin=mysql-bin' >> /etc/mysql/my.cnf"
docker restart $SLAVE2_CONTAINER

# Configurar el Slave2 para que se conecte al Master
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "
CHANGE MASTER TO
    MASTER_HOST = '$MASTER_IP',
    MASTER_USER = '$REPLICA_USER',
    MASTER_PASSWORD = '$REPLICA_PASSWORD',
    MASTER_LOG_FILE = '$MASTER_LOG_FILE',
    MASTER_LOG_POS = $MASTER_LOG_POS;
START SLAVE;
"

# 5. Verificar que la replicación está funcionando
echo "Verificando el estado de la replicación..."

# En Slave1
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running"

# En Slave2
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running"
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running"

# 6. Insertar base de datos y tabla desde el archivo init.sql
if [ -f "$INIT_SQL_FILE" ]; then
    echo "Ejecutando archivo init.sql para insertar la base de datos..."
    docker exec -i $MASTER_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD < $INIT_SQL_FILE
else
    echo "No se encontró el archivo init.sql"
fi

# 7. Verificar replicación de los datos
echo "Verificando que los datos se replican en el Slave1..."
docker exec -it $SLAVE1_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"

echo "Verificando que los datos se replican en el Slave2..."
docker exec -it $SLAVE2_CONTAINER mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"

echo "Configuración de la replicación MySQL con Docker completada."
