#!/usr/bin/env bash
set -euo pipefail

# 1. mysite klasörünü oluştur
mkdir -p "$HOME/mysite"

# 2. Paketleri yükle
sudo apt update
sudo apt install -y unzip nginx

# 3. Diode CLI yükle
curl -sSf https://diode.io/install.sh | sh

# 4. .bashrc’yi kaynakla (eklenmiş PATH için)
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

# 6. Site’ı etkinleştir ve Nginx’i test edip yeniden başlat
sudo ln -sf /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/mysite
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 7. Kendini kopyalayıp çalıştırılabilir yap (systemd için)
SCRIPT_PATH="/usr/local/bin/mysite-setup.sh"
sudo cp "$0" "$SCRIPT_PATH"
sudo chmod +x "$SCRIPT_PATH"

# 8. Systemd birimi oluştur
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

# 9. systemd’yi yenile, servisi etkinleştir ve ayağa kaldır
sudo systemctl daemon-reload
sudo systemctl enable mysite-setup.service
sudo systemctl start mysite-setup.service

echo "✅ mysite kurulumu, Nginx config ve systemd servisi başarıyla hazırlandı!"
