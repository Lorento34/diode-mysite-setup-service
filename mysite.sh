#!/usr/bin/env bash
set -euo pipefail

# 0. Raw script URL’in (main branch) ve kopyalanacağı yol
SCRIPT_URL="https://raw.githubusercontent.com/Lorento34/diode-mysite-setup-service/main/mysite.sh"
SCRIPT_PATH="/usr/local/bin/mysite.sh"

# 1. mysite klasörünü oluştur
mkdir -p "$HOME/mysite"

# 2. Gerekli paketleri yükle
sudo apt update
sudo apt install -y unzip nginx curl

# 3. Diode CLI yükle
curl -sSf https://diode.io/install.sh | sh

# 4. .bashrc’yi kaynakla (PATH güncellemesi için)
if [[ -f "$HOME/.bashrc" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"
fi

# 5. Nginx site konfigürasyonu oluştur
sudo tee /etc/nginx/sites-available/mysite > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root $HOME/mysite;
    index index.html;
    server_name _;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# 6. Site’ı etkinleştir, Nginx’i test et ve yeniden başlat
sudo ln -sf /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/mysite
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 7. Kendini güncel haliyle /usr/local/bin’e indir
sudo curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
sudo chmod +x "$SCRIPT_PATH"

# 8. systemd servis birimini oluştur
sudo tee /etc/systemd/system/mysite-setup.service > /dev/null <<EOF
[Unit]
Description=MySite & Diode Setup Service
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 9. systemd’yi yenile, servisi etkinleştir ve başlat
sudo systemctl daemon-reload
sudo systemctl enable mysite-setup
sudo systemctl start mysite-setup

echo "✅ mysite kurulumu, Nginx config ve systemd servisi başarıyla hazırlandı!"
