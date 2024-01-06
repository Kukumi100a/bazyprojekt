
#!/bin/bash

# Path to the database
DB_PATH=/firebird/data/$FIREBIRD_DATABASE

# Create the database if it doesn't exist
if [ ! -f "$DB_PATH" ]; then
    echo "Creating Firebird database $FIREBIRD_DATABASE..."
    gfix -create "$DB_PATH" -user $FIREBIRD_USER -password $FIREBIRD_PASSWORD
    echo "Database $FIREBIRD_DATABASE created successfully."
else
    echo "Database $FIREBIRD_DATABASE already exists."
fi
