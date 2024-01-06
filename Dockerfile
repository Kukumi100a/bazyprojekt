
FROM jacobalberty/firebird:latest

# Environment variables for database creation
ENV FIREBIRD_DATABASE=dane.fdb
ENV FIREBIRD_USER=SYSDBA
ENV FIREBIRD_PASSWORD=masterkey

# Copy the database creation script
COPY create_db.sh /docker-entrypoint-initdb.d/
