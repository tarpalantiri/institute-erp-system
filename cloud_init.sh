#!/bin/bash

# CLOUD INIT SCRIPT FOR COLLEGE-ERP DJANGO PROJECT SETUP ON UBUNTU 20.04 EC2

PROJECT_REPO_HTTPS="https://github.com/tarpalantiri/institute-erp-system.git"
PROJECT_NAME="institute-erp-system"
PROJECT_DIR="/var/www/institute-erp-system"
EC2_PUBLIC_DNS=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

apt update
apt upgrade -y
apt install gcc apache2 mysql-server libmysqlclient-dev libapache2-mod-wsgi-py3 python3.8-venv python3-pip libpq-dev -y
apt install python3-dev python3-pip python3-wheel -y
pip3 install wheel

git clone $PROJECT_REPO_HTTPS
mv $PROJECT_NAME /var/www/

echo "STATIC_ROOT = os.path.join(BASE_DIR, \"static/\")" >> $PROJECT_DIR/CollegeERP/settings.py
echo "STATICFILES = [STATIC_ROOT]" >> $PROJECT_DIR/CollegeERP/settings.py
python3 -m venv $PROJECT_DIR/env
source $PROJECT_DIR/env/bin/activate
pip3 install -r $PROJECT_DIR/requirements.txt

python3 $PROJECT_DIR/manage.py collectstatic
python3 $PROJECT_DIR/manage.py makemigrations
python3 $PROJECT_DIR/manage.py migrate

chmod 664 $PROJECT_DIR/db.sqlite3
chown :www-data $PROJECT_DIR/
chown :www-data $PROJECT_DIR/db.sqlite3
chown :www-data $PROJECT_DIR/CollegeERP

rm -rf /var/www/html

mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf_backup
echo "<VirtualHost *:80>
        ServerAdmin tehseensajjadsb@gmail.com
        ServerName $EC2_PUBLIC_DNS
        DocumentRoot $PROJECT_DIR

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        Alias /static $PROJECT_DIR/static
        <Directory $PROJECT_DIR/static>
            Require all granted
        </Directory>

        <Directory $PROJECT_DIR/CollegeERP>
            <Files wsgi.py>
                Require all granted
            </Files>
        </Directory>

        WSGIPassAuthorization On
        WSGIDaemonProcess College-ERP python-path=$PROJECT_DIR python-home=$PROJECT_DIR/env
        WSGIProcessGroup College-ERP
        WSGIScriptAlias / $PROJECT_DIR/CollegeERP/wsgi.py
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

a2ensite 000-default.conf
a2enmod wsgi
a2enmod rewrite
service apache2 restart
