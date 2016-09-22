#!/bin/bash


MI_DOMINIO="python.jrgware.es"


clear

if [ "$EUID" -ne 0 ]
  then echo "Please run as root ( with sudo )"
  exit
fi

if ! which nginx > /dev/null 2>&1; then
    echo "Nginx not installed, please install it before running this script"
    echo "$ sudo apt-get update && sudo apt-get install nginx"
    exit
fi


if ! which certbot-auto > /dev/null 2>&1; then
    echo "El cliente LetsEncrypt no está instalado. Vamos a ello ...."

 if ! which wget > /dev/null 2>&1; then
     sudo apt-get update -y 1>/dev/null && sudo apt-get install wget -y 1>/dev/null
 fi

    cd /usr/local/sbin
    wget https://dl.eff.org/certbot-auto
    chmod a+x /usr/local/sbin/certbot-autos
fi


if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    echo "Grupo Diffie-Hellman no existe. Vamos a crear uno para incrementar la seguridad."
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
fi


echo "Eliminando directorio "/var/www/$MI_DOMINIO/
rm /var/www/$MI_DOMINIO/ -rf

mkdir /var/www/$MI_DOMINIO
echo "Creando directorio "/var/www/$MI_DOMINIO/

echo "Generando HTML básico en "/var/www/$MI_DOMINIO/index.html
echo "Hola desde:" $MI_DOMINIO > /var/www/$MI_DOMINIO/index.html 


echo "Generando Configuración Nginx básica"
cat << EOF > /etc/nginx/sites-available/$MI_DOMINIO
server {

    listen 80;     

    server_name $MI_DOMINIO;

    root /var/www/$MI_DOMINIO;
    index index.html index.htm;


    location / {
     try_files \$uri \$uri/ =404;
    }

    # letsEncrypt
    location ~ /.well-known {
     allow all;
    }

}
EOF
ls /etc/nginx/sites-available/$MI_DOMINIO

echo "Activando sitio Nginx"
ln -s /etc/nginx/sites-available/$MI_DOMINIO /etc/nginx/sites-enabled/$MI_DOMINIO 2>/dev/null
ls /etc/nginx/sites-enabled/$MI_DOMINIO
service nginx restart

echo "Requiriendo Certificado LetsEncrypt"
certbot-auto certonly -a webroot --webroot-path=/var/www/$MI_DOMINIO -d $MI_DOMINIO

echo "Generando Configuración Nginx SSL"
cat << EOF > /etc/nginx/sites-available/$MI_DOMINIO
server {

    listen 443 ssl;     

    server_name $MI_DOMINIO;

    ssl_certificate /etc/letsencrypt/live/$MI_DOMINIO/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$MI_DOMINIO/privkey.pem;

    root /var/www/$MI_DOMINIO;
    index index.html index.htm;


    location / {
        try_files \$uri \$uri/ =404;
    }

    # letsEncrypt
    location ~ /.well-known {
        allow all;
    }

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security max-age=15768000;

}

server {
    listen 80;
    server_name $MI_DOMINIO;
    return 301 https://\$host\$request_uri;
}
EOF


echo "Reiniciando Nginx"
service nginx restart

echo "Recuerda introducir la tarea en CRON para renovar los certificados si no existe:"
printf "(tip)\n\$ sudo crontab -e\n\n\tañadir siguientes entradas: ( ejecutar todos los lunes a las 2:30 y 2:35 am )\n\n\t30 2 * * 1 /usr/local/sbin/certbot-auto renew >> /var/log/le-renew.log\n\t35 2 * * 1 /etc/init.d/nginx reload"

printf "\n\nFin del proceso"