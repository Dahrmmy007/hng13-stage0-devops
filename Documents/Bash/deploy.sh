
#!/bin/bash

# HNG DevOps Stage 1 - Automated Deployment
# Author: Ologbon Damilola

set -e

# Create log file with timestamp
LOG_FILE="deploy$(date +'%Y%m%d_%H%M%S').log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

echo "=============================="
echo "🚀 DevOps Automated Deployment"
echo "=============================="

# 1. Collect User Inputs
# ------------------------------
read -p "Enter Git Repository URL: " REPO_URL
read -p "Enter Personal Access Token: " PAT
read -p "Enter Branch name [default: main]: " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter Remote Server Username: " SSH_USER
read -p "Enter Remote Server IP: " SERVER_IP
read -p "Enter SSH key path: " SSH_KEY
read -p "Enter Application port (e.g., 5000): " APP_PORT

if [ -z "$REPO_URL" ] || [ -z "$PAT" ] || [ -z "$SSH_USER" ] || [ -z "$SERVER_IP" ]; then
  echo "All fields are required. Please try again."
  exit 1
fi

# 2. Clone the Repository
# ------------------------------
REPO_DIR=$(basename "$REPO_URL" .git)

if [ -d "$REPO_DIR" ]; then
  echo "Repository exists, pulling latest changes..."
  cd "$REPO_DIR" && git pull
else
  echo "Cloning repository..."
  git clone https://$PAT@${REPO_URL#https://} && cd "$REPO_DIR"
fi

git checkout "$BRANCH"

if [ ! -f Dockerfile ] && [ ! -f docker-compose.yml ]; then
  echo "No Dockerfile or docker-compose.yml found. Aborting."
  exit 1
fi

# 3. Test SSH Connection
# ------------------------------
echo "Testing connection to remote server..."
ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 "$SSH_USER@$SERVER_IP" "echo 'SSH connection successful!'" || {
  echo "SSH connection failed. Check credentials or key permissions."
  exit 1

# 4. Prepare Remote Environment
# ------------------------------
echo "Setting up environment on remote server..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" <<EOF
  set -e
  sudo apt update -y
  sudo apt install -y docker.io docker-compose nginx
  sudo systemctl enable docker
  sudo systemctl start docker
  echo "Docker and Nginx installed successfully."
EOF

# 5. Transfer Files
# ------------------------------
echo "Transferring project files..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "rm -rf ~/app && mkdir ~/app"
scp -i "$SSH_KEY" -r ./* "$SSH_USER@$SERVER_IP:~/app"


# 6. Build and Run Containers
# ------------------------------
echo "Building and starting Docker containers..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" <<EOF
  cd ~/app
  if [ -f docker-compose.yml ]; then
    docker-compose down || true
    docker-compose up -d --build
  else
    docker stop myapp || true
    docker rm myapp || true
    docker build -t myapp .
    docker run -d -p $APP_PORT:$APP_PORT --name myapp myapp
  fi
EOF


# 7. Configure Nginx Reverse Proxy
# ------------------------------
echo "Configuring Nginx reverse proxy..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" <<EOF
sudo bash -c 'cat > /etc/nginx/sites-available/app.conf <<NGINX
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINX'
sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
EOF


# 8. Validate Deployment
# ------------------------------
echo "Validating deployment..."
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" <<EOF
  echo "Docker containers running:"
  docker ps
  echo "Checking Nginx status:"
  sudo systemctl status nginx | grep active
  echo "Testing HTTP response:"
  curl -I localhost || true
EOF


# 9. Optional Cleanup Flag
# ------------------------------
if [[ $1 == "--cleanup" ]]; then
  echo "Cleaning up deployment..."
  ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "sudo rm -rf ~/app && docker system prune -af"
  echo "Cleanup complete."
  exit 0
fi
    

# 10. Completion Message
# ------------------------------
echo "✅ Deployment complete! Check your app on the server IP via port 80."
echo "Log file saved as $LOG_FILE"
