#!/bin/bash
# ================================================================
# EC2 Setup Script — Run once on fresh Ubuntu 22.04 t2.micro
# Works for both staging and production instances
# Usage: chmod +x setup-ec2.sh && sudo ./setup-ec2.sh
# ================================================================

set -e
echo "🚀 Starting EC2 setup for Node.js CI/CD demo..."

# ── System update ──────────────────────────────────────────────
apt-get update -y
apt-get upgrade -y

# ── Install Docker ─────────────────────────────────────────────
echo "📦 Installing Docker..."
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

echo "✅ Docker installed: $(docker --version)"

# ── Install AWS CLI v2 ─────────────────────────────────────────
echo "📦 Installing AWS CLI..."
apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

echo "✅ AWS CLI installed: $(aws --version)"

# ── Install Nginx (reverse proxy) ─────────────────────────────
echo "📦 Installing Nginx..."
apt-get install -y nginx

# Basic Nginx config — proxies port 80 → app port 3000
cat > /etc/nginx/sites-available/nodejs-app << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/nodejs-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "✅ Nginx configured"

# ── Security: basic UFW firewall ───────────────────────────────
apt-get install -y ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp    # direct app access for health checks
ufw --force enable

echo "✅ Firewall configured"

# ── Useful monitoring tools ────────────────────────────────────
apt-get install -y htop curl jq

echo ""
echo "✅ ═══════════════════════════════════════════"
echo "   EC2 setup complete!"
echo "   Next steps:"
echo "   1. Add GitHub Secrets (see README)"
echo "   2. Create ECR repository in AWS Console"
echo "   3. Push to 'develop' branch to trigger staging deploy"
echo "═══════════════════════════════════════════"
