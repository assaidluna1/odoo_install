#!/bin/bash

# Script de instalación de Odoo 18 para ambiente productivo/pruebas en Ubuntu 24.04 LTS

echo "=== Actualizando sistema ==="
sudo apt-get update
sudo apt-get upgrade -y

echo "=== Instalando dependencias de Python y librerías esenciales ==="
sudo apt-get install -y python3-pip python3-dev libxml2-dev libxslt1-dev zlib1g-dev \
libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev \
libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev

echo "=== Instalando Node.js, Less y plugins ==="
sudo ln -sf /usr/bin/nodejs /usr/bin/node
sudo apt-get install -y npm node-less
sudo npm install -g less less-plugin-clean-css

echo "=== Instalando PostgreSQL ==="
sudo apt-get install -y postgresql

echo "=== Crear usuario PostgreSQL para Odoo (ejecutar manualmente) ==="
echo "sudo su - postgres"
echo "createuser --createdb --username postgres --no-createrole --superuser --pwprompt odoo18"
echo "exit"
read -p "Presiona [Enter] cuando hayas creado el usuario en PostgreSQL..."

echo "=== Crear usuario de sistema para Odoo 18 ==="
sudo adduser --system --home=/opt/odoo18 --group odoo18

echo "=== Instalando Git y clonando Odoo ==="
sudo apt-get install -y git
sudo su - odoo18 -s /bin/bash -c 'git clone https://www.github.com/odoo/odoo --depth 1 --branch master --single-branch /opt/odoo18'

echo "=== Instalando entorno virtual de Python ==="
sudo apt install -y python3-venv
sudo python3 -m venv /opt/odoo18/venv

echo "=== Instalando dependencias Python de Odoo ==="
sudo -s <<EOF
cd /opt/odoo18/
source venv/bin/activate
pip install -r requirements.txt
deactivate
EOF

echo "=== Instalando wkhtmltopdf y dependencias ==="
cd /tmp
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.1/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo apt-get install -y xfonts-75dpi
sudo dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo apt install -f -y

echo "=== Configurando Odoo ==="
sudo cp /opt/odoo18/debian/odoo.conf /etc/odoo18.conf
sudo tee /etc/odoo18.conf > /dev/null <<EOL
[options]
db_host = localhost
db_port = 5432
db_user = odoo18
db_password = 123456
addons_path = /opt/odoo18/addons
default_productivity_apps = True
logfile = /var/log/odoo/odoo18.log
EOL

sudo chown odoo18: /etc/odoo18.conf
sudo chmod 640 /etc/odoo18.conf

echo "=== Creando directorio de logs ==="
sudo mkdir -p /var/log/odoo
sudo chown odoo18:root /var/log/odoo

echo "=== Creando archivo de servicio systemd para Odoo 18 ==="
sudo tee /etc/systemd/system/odoo18.service > /dev/null <<EOL
[Unit]
Description=Odoo18
Documentation=http://www.odoo.com

[Service]
Type=simple
User=odoo18
ExecStart=/opt/odoo18/venv/bin/python3 /opt/odoo18/odoo-bin -c /etc/odoo18.conf

[Install]
WantedBy=default.target
EOL

sudo chmod 755 /etc/systemd/system/odoo18.service
sudo chown root: /etc/systemd/system/odoo18.service

echo "=== Iniciando servicio Odoo 18 ==="
sudo systemctl daemon-reload
sudo systemctl start odoo18.service
sudo systemctl enable odoo18.service

echo "=== Instalación completada ==="
echo "Accede a Odoo en: http://<tu_IP>:8069"