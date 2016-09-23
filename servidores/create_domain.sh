#!/bin/bash
# ******************************************************************
# ** Description : Configure a basic web nginx site with ssl (letsEncrypt)
# ** File        : create_domain.sh
# ** Version     : 1.0
# ** Maintainer  : Juan R. Gavilanes
# ** Date        : 2016-09-22
# ******************************************************************


#Styles
red=$( echo -e "\033[1;31;40m" )
green=$( echo -e "\033[1;32;40m" )
none=$( echo -e "\033[0m" )


clear

if [ "$EUID" -ne 0 ]
  then echo $red"Please run as root ( with sudo )"$none
  exit
fi


# Ask for the new Domain name.
read -p $green"Introduzca su dominio (ej: jrgware.es ):? "$none MI_DOMINIO
while [[ -z "$MI_DOMINIO" ]]; do
    read -p $red"Necesito un dominio! (ej: jrgware.es ):? "$none MI_DOMINIO
done


echo ""
read -p $none"Ha introducido "$green$MI_DOMINIO$none", desea continuar?: [S/n]" sigo
while [[ -z "$sigo" ]]; do
    sigo="S"
done

if [[ ! $sigo =~ [Ss]{1} ]]; then

    printf $red"\nHa seleccionado salir!\n"$none

    exit

fi


if ! which nginx > /dev/null 2>&1; then
    echo $red
        echo "Nginx not installed, please install it before running this script"
        echo "$ sudo apt-get update && sudo apt-get install nginx"
    echo $none
    exit
fi


if ! which certbot-auto > /dev/null 2>&1; then
    echo $green"El cliente LetsEncrypt no está instalado. Vamos a ello ...."$none

 if ! which wget > /dev/null 2>&1; then
     sudo apt-get update -y 1>/dev/null && sudo apt-get install wget -y 1>/dev/null
 fi

    cd /usr/local/sbin
    wget https://dl.eff.org/certbot-auto
    chmod a+x /usr/local/sbin/certbot-auto
fi


if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    echo $green"Grupo Diffie-Hellman no existe. Vamos a crear uno para incrementar la seguridad."$none    
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
fi


echo $green

    echo "Eliminando directorio "/var/www/$MI_DOMINIO/
    echo ""
    sudo rm /var/www/$MI_DOMINIO/ -rf

    echo "Creando directorio "/var/www/$MI_DOMINIO/
    echo ""
    sudo mkdir /var/www/$MI_DOMINIO


    echo "Generando HTML básico en "/var/www/$MI_DOMINIO/index.html
    echo ""

    echo "Hola desde:" $MI_DOMINIO > /var/www/$MI_DOMINIO/index.html 

    echo "Generando Configuración Nginx básica"
    echo ""

echo $none

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

echo $green"Activando sitio Nginx"$none
echo ""
sudo ln -s /etc/nginx/sites-available/$MI_DOMINIO /etc/nginx/sites-enabled/$MI_DOMINIO 2>/dev/null
sudo ls /etc/nginx/sites-enabled/$MI_DOMINIO
sudo service nginx restart

echo $green"Requiriendo Certificado LetsEncrypt"$none
echo ""
sudo certbot-auto certonly -a webroot --webroot-path=/var/www/$MI_DOMINIO -d $MI_DOMINIO

echo $green"Generando Configuración Nginx SSL"$none
echo ""
cat << EOF > /etc/nginx/sites-available/$MI_DOMINIO

# upstream $MI_DOMINIO_docker {

#     server localhost:3000;

# }

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

    # location / {

    #     proxy_pass http://$MI_DOMINIO_docker;

    # }

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
echo ""
sudo service nginx restart


printf "\nCompueba la calidad del certificado entrando en la siguiente dirección:\n"
echo $green
printf "\n\thttps://www.ssllabs.com/ssltest/analyze.html?d="$MI_DOMINIO
echo $none


echo ""
echo "Recuerda introducir la tarea en CRON para renovar los certificados si no existe:"
echo $red
printf "(tip)\n\$ sudo crontab -e\n\n"
printf "\tañadir siguientes entradas: ( ejecutar todos los lunes a las 2:30 y 2:35 am )\n\n"
printf "\t30 2 * * 1 /usr/local/sbin/certbot-auto renew >> /var/log/le-renew.log\n"
printf "\t35 2 * * 1 /etc/init.d/nginx reload"
echo $none

printf $green"\n\nFin del proceso\n\n"$none