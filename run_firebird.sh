
#!/bin/bash

IMAGE_NAME="custom-firebird"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Check if the image already exists
if [[ "$(docker images -q $FULL_IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Building $FULL_IMAGE_NAME..."
    docker build -t $FULL_IMAGE_NAME .
else
    echo "$FULL_IMAGE_NAME already exists."
fi

# Create a directory for Firebird data
FIREBIRD_DATA_DIR="/tmp/firebird_data_$(date +%s)"
mkdir -p "$FIREBIRD_DATA_DIR"

# Run the Docker container
docker run -d --name firebird-server -v "$FIREBIRD_DATA_DIR:/firebird/data" -p 3050:3050 $FULL_IMAGE_NAME
