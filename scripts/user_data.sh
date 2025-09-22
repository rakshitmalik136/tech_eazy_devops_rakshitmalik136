#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log all output for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting TechEazy Application Setup ==="
echo "Timestamp: $(date)"

# Update package lists and install necessary software
echo "--- Updating system packages and installing dependencies ---"
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk maven git

# Verify installations
echo "--- Verifying installations ---"
java -version
mvn -version

# Define the repository and application directory
REPO_URL="https://github.com/Trainings-TechEazy/test-repo-for-devops"
APP_DIR="/opt/techeazy-app"

# Create application directory
echo "--- Creating application directory ---"
sudo mkdir -p "$APP_DIR"

# Clone the repository
echo "--- Cloning application repository from GitHub ---"
sudo git clone "$REPO_URL" "$APP_DIR"

# Change ownership to ubuntu user
sudo chown -R ubuntu:ubuntu "$APP_DIR"

# Navigate to the app directory and build the application
echo "--- Building the application with Maven ---"
cd "$APP_DIR"
mvn clean package

# Find the JAR file
JAR_FILE=$(find target -name '*.jar' | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "ERROR: No JAR file found after Maven build"
    exit 1
fi

echo "--- Found JAR file: $JAR_FILE ---"

# Create a systemd service for the application
echo "--- Creating systemd service ---"
sudo tee /etc/systemd/system/techeazy-app.service > /dev/null <<EOF
[Unit]
Description=TechEazy Java Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/java -jar $APP_DIR/$JAR_FILE
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
echo "--- Starting application service ---"
sudo systemctl daemon-reload
sudo systemctl enable techeazy-app.service
sudo systemctl start techeazy-app.service

# Wait a moment and check if service is running
sleep 10
if sudo systemctl is-active --quiet techeazy-app.service; then
    echo "--- Application service started successfully ---"
    sudo systemctl status techeazy-app.service --no-pager
else
    echo "ERROR: Application service failed to start"
    sudo systemctl status techeazy-app.service --no-pager
    exit 1
fi

echo "=== TechEazy Application Setup Complete ==="
echo "Application should be accessible on port 8080"
