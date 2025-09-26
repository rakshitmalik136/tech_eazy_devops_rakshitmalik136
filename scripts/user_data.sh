#!/bin/bash

# Exit on any error
set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting TechEazy Application Setup ==="
echo "Timestamp: $(date)"

# S3 bucket name passed from Terraform
S3_BUCKET="${bucket_name}"
echo "S3 Bucket for logs: $S3_BUCKET"

# Update and install packages
echo "--- Installing dependencies ---"
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk maven git curl awscli

# Verify installations
echo "--- Java and AWS CLI version check ---"
java -version
mvn -version
aws --version

# Application setup
REPO_URL="https://github.com/Trainings-TechEazy/test-repo-for-devops"
APP_DIR="/opt/techeazy-app"

echo "--- Setting up application directory ---"
sudo mkdir -p "$APP_DIR"
sudo mkdir -p "$APP_DIR/logs"
sudo chown -R ubuntu:ubuntu "$APP_DIR"

echo "--- Cloning repository ---"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

echo "--- Building application ---"
mvn clean package -DskipTests

# Find JAR file
JAR_FILE=$(find target -name '*.jar' -type f | head -n 1)
if [ -z "$JAR_FILE" ]; then
    echo "ERROR: No JAR file found!"
    find . -name "*.jar" -type f
    exit 1
fi

echo "--- Found JAR: $JAR_FILE ---"

# Create systemd service with logging
echo "--- Creating systemd service with file logging ---"
sudo tee /etc/systemd/system/techeazy-app.service > /dev/null <<EOF
[Unit]
Description=TechEazy Java Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/java -server -Xmx512m -jar $APP_DIR/$JAR_FILE --server.port=8080 --server.address=0.0.0.0
Restart=always
RestartSec=30

# Logging configuration
StandardOutput=append:$APP_DIR/logs/application.log
StandardError=append:$APP_DIR/logs/application-error.log

# Environment
Environment=JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
Environment=AWS_DEFAULT_REGION=us-east-1

[Install]
WantedBy=multi-user.target
EOF

# Start service
echo "--- Starting application service ---"
sudo systemctl daemon-reload
sudo systemctl enable techeazy-app.service
sudo systemctl start techeazy-app.service

# Wait and check
echo "--- Waiting for application to start ---"
sleep 30

# Check service status
if sudo systemctl is-active --quiet techeazy-app.service; then
    echo "Service is running!"
    sudo systemctl status techeazy-app.service --no-pager
else
    echo "Service failed to start"
    sudo systemctl status techeazy-app.service --no-pager
    echo "--- Service logs ---"
    sudo journalctl -u techeazy-app.service --no-pager -n 50
fi

# Test local connectivity
echo "--- Testing local connectivity ---"
sleep 10
curl -f http://localhost:8080/hello || echo "Local connection test failed"

# 4. Upload EC2 logs to S3 bucket after instance setup
echo "--- Uploading EC2 setup logs to S3 ---"
if [ -n "$S3_BUCKET" ]; then
    # Create directory structure in S3
    aws s3 cp /var/log/user-data.log "s3://$S3_BUCKET/ec2-logs/user-data-$(date +%Y%m%d-%H%M%S).log" || echo "Failed to upload user-data.log"
    aws s3 cp /var/log/cloud-init-output.log "s3://$S3_BUCKET/ec2-logs/cloud-init-$(date +%Y%m%d-%H%M%S).log" 2>/dev/null || echo "cloud-init-output.log not found"
    
    # 5. Upload application logs
    sleep 5
    if [ -f "$APP_DIR/logs/application.log" ]; then
        aws s3 cp "$APP_DIR/logs/application.log" "s3://$S3_BUCKET/app-logs/application-$(date +%Y%m%d-%H%M%S).log" || echo "Failed to upload application.log"
    fi
    
    echo "--- Logs uploaded to S3 bucket: $S3_BUCKET ---"
else
    echo "--- No S3 bucket specified, skipping log upload ---"
fi

# Create a script for periodic log uploads
echo "--- Creating log upload script ---"
sudo tee /usr/local/bin/upload-logs.sh > /dev/null <<EOF
#!/bin/bash
if [ -n "$S3_BUCKET" ]; then
    # Upload application logs
    if [ -f "$APP_DIR/logs/application.log" ]; then
        aws s3 cp "$APP_DIR/logs/application.log" "s3://$S3_BUCKET/app-logs/application-\$(date +%Y%m%d-%H%M%S).log"
    fi
    if [ -f "$APP_DIR/logs/application-error.log" ]; then
        aws s3 cp "$APP_DIR/logs/application-error.log" "s3://$S3_BUCKET/app-logs/application-error-\$(date +%Y%m%d-%H%M%S).log"
    fi
    
    # Upload system logs
    aws s3 cp /var/log/syslog "s3://$S3_BUCKET/system-logs/syslog-\$(date +%Y%m%d-%H%M%S).log" 2>/dev/null || true
fi
EOF

sudo chmod +x /usr/local/bin/upload-logs.sh

# 7. Test S3 access with read-only role
echo "--- Testing S3 access ---"
if [ -n "$S3_BUCKET" ]; then
    echo "Testing S3 list access:"
    aws s3 ls "s3://$S3_BUCKET" || echo "S3 list failed - check IAM permissions"
    
    echo "Testing S3 read access:"
    aws s3 ls "s3://$S3_BUCKET/ec2-logs/" || echo "S3 read access test completed"
fi

echo "=== Setup completed at $(date) ==="
echo "S3 Bucket: $S3_BUCKET"
echo "Application logs will be stored in: $APP_DIR/logs/"
echo "Periodic log uploads configured via /usr/local/bin/upload-logs.sh"