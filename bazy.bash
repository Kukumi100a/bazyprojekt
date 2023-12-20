#!/bin/bash

# Necessary things for MongoDB

apt-get install gnupg
wget -qO- https://www.mongodb.org/static/pgp/server-7.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-7.0.asc
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list


# Necessary things for ArangoDB

wget -qO - https://download.arangodb.com/arangodb36/DEBIAN/Release.key | sudo apt-key add -
echo 'deb https://download.arangodb.com/arangodb36/DEBIAN/ /' | sudo tee /etc/apt/sources.list.d/arangodb.list



# Update package lists
apt-get update

apt-get install -y docker.io \
                   default-mysql-client \
                   firebird3.0-utils \
                   mongodb-mongosh \
                   arangodb3-client \
                   nmap

# Function to check if a Docker image is available locally and pull it if not
check_and_pull() {
    if [[ -z $(docker images -q "$1") ]]; then
        docker pull "$1"
    fi
}


# MySQL
check_and_pull mysql
docker run --name mysql-container -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 -d mysql

# Firebird
check_and_pull jacobalberty/firebird
docker run --name firebird-container -e ISC_PASSWORD=root -p 3050:3050 -d jacobalberty/firebird

# MongoDB
check_and_pull mongo
docker run --name mongodb-container -e MONGO_INITDB_ROOT_USERNAME=root -e MONGO_INITDB_ROOT_PASSWORD=root -p 27017:27017 -d mongo:4.4.6

# RethinkDB
check_and_pull rethinkdb
docker run --name rethinkdb-container -e RETHINKDB_ADMIN_PASSWORD=root -p 8080:8080 -p 28015:28015 -p 29015:29015 -d rethinkdb

# Neo4j
check_and_pull neo4j
docker run --name neo4j-container -e NEO4J_AUTH=neo4j/root123456789 -p 7474:7474 -p 7687:7687 -d neo4j

# ArangoDB
check_and_pull arangodb
docker run --name arangodb-container -e ARANGO_ROOT_PASSWORD=root -p 8529:8529 -d arangodb:3.8.9

# Wait for containers to initialize
sleep 45

# Function to check the status of each database
check_database() {
    local host=$1
    local port=$2

    echo "Checking database on $host:$port..."

    if nc -zv "$host" "$port"; then
        case $port in
            3306) # MySQL
                if mysql -h "localhost" -P "3306" -u root -proot -e 'SELECT 1;' &> /dev/null; then
                    echo "Connected to MySQL database."
                else
                    echo "Connection failed to MySQL database."
                fi
                ;;
	    3050) # Firebird
	        if isql-fb -user SYSDBA -password root "$host/$port:employee.fdb" -q -i /dev/null &> /dev/null; then
		    echo "Connected to Firebird database."
	        else
		    echo "Connection failed to Firebird database."
	        fi
	        ;;
            27017) # MongoDB
                if mongosh --host "$host" --port "$port" -u root -p root --authenticationDatabase admin --eval "quit();" &> /dev/null; then
                    echo "Connected to MongoDB database."
                else
                    echo "Connection failed to MongoDB database."
                fi
                ;;
	    8529) # ArangoDB
		if arangosh --server.endpoint tcp://localhost:8529 --server.username root --server.password root --javascript.execute-string "print('Connected to ArangoDB database.');" &> /dev/null; then
		    echo "Connected to ArangoDB database."
		else
	            echo "Connection failed to ArangoDB database."
		fi
		;;
	    7687) # Neo4j
	        if docker run --rm --network=host neo4j cypher-shell -a bolt://"$host":7687 -u neo4j -p root123456789 "RETURN 'Connected';" &> /dev/null; then
		    echo "Connected to Neo4j database."
	        else
		    echo "Connection failed to Neo4j database."
	        fi
	        ;;
	    28015) # RethinkDB
		if docker run --rm -it --network host rethinkdb rethinkdb --version &> /dev/null; then
		    echo "Connected to RethinkDB database."
		else
	            echo "Connection failed to RethinkDB database."
		fi
	        ;;
            *)
                echo "No recognized database found on $host:$port."
                ;;
        esac
    else
        echo "Connection failed."
    fi
}

# Check databases
check_database "localhost" "3306"
check_database "localhost" "3050"
check_database "localhost" "27017"
check_database "localhost" "28015"
check_database "localhost" "7687"
check_database "localhost" "8529"

echo "MYSQL: Port 3306"
echo "Firebird: Port 3050"
echo "MongoDB: Port 27017"
echo "RethinkDB: Port 28015"
echo "Neo4j: Port 7687"
echo "ArangoDB: Port 8529"
echo "Username and password for each database: 'root'*"
echo "* - Neo4j has username neo4j and password root123456789"
echo "*2 - Firebird: user: SYSDBA password: root"
