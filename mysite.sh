#!/usr/bin/env bash

# 0. PS1'i önceden tanımlayarak "unbound variable" hatasını önleyelim
export PS1=""

# 1. Hata / kullanımda olmayan değişken kontrolü vs.
set -euo pipefail

# 2. Raw script URL’in (main branch) ve kopyalanacağı yer
SCRIPT_URL="https://raw.githubusercontent.com/Lorento34/diode-mysite-setup-service/main/mysite.sh"
SCRIPT_PATH="/usr/local/bin/mysite.sh"

# 3. mysite klasörünü oluştur
mkdir -p "$HOME/mysite"

# 4. Gerekli paketleri yükle
sudo apt update
sudo apt install -y unzip nginx curl

# 5. Diode CLI yükle
curl -sSf https://diode.io/install.sh | sh

# 6. ~/.bashrc’ye PATH ekle (tekrarlanmaması için kontrol ederek) ve geçici export et
if ! grep -q '/root/opt/diode' "$HOME/.bashrc"; then
  echo 'export PATH=/root/opt/diode:$PATH' >> "$HOME/.bashrc"
fi
export PATH=/root/opt/diode:$PATH

# 7. Nginx site konfigürasyonu oluştur
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

# 8. Site’ı etkinleştir, Nginx’i test et ve yeniden başlat
sudo ln -sf /etc/nginx/sites-available/mysite /etc/nginx/sites-enabled/mysite
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 9. Script’in güncel halini /usr/local/bin’e indir ve izin ver
sudo curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
sudo chmod +x "$SCRIPT_PATH"

# 10. systemd servis birimini oluştur
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

# 11. systemd’yi yenile, servisi etkinleştir ve başlat
sudo systemctl daemon-reload
sudo systemctl enable mysite-setup
sudo systemctl start mysite-setup

echo "✅ mysite kurulumu, Nginx config ve systemd servisi başarıyla hazırlandı!"
