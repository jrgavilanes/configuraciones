#!/bin/bash
# *******************************************************************************
# ** Description : Configure a basic web nginx Docker-site with ssl (letsEncrypt)
# ** File        : create_domain_docker.sh
# ** Version     : 1.0
# ** Maintainer  : Juan R. Gavilanes
# ** Date        : 2017-07-29
# *******************************************************************************


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

# Ask for the Docker port
sigo="N"
read -p $green"Que puerto local redirecciona a la aplicación Docker (ej: 3000):? "$none MI_DOCKER_PORT
while [[ -z "$MI_DOCKER_PORT" ]]; do
    read -p $red"Necesito un puerto! (ej: 3000 ):? "$none MI_DOCKER_PORT
done


echo ""
read -p $none"Ha introducido "$green$MI_DOCKER_PORT$none", desea continuar?: [S/n]" sigo
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

    echo "Generando Configuración Nginx básica"
    echo ""

echo $none


#HTML básico
cat << EOF > /var/www/$MI_DOMINIO/index.html
<!doctype html>
<title>$MI_DOMINIO - Site Maintenance</title>
<style>
  body { text-align: center; padding: 150px; }
  h1 { font-size: 50px; }
  body { font: 20px Helvetica, sans-serif; color: #333; }
  article { display: block; text-align: left; width: 650px; margin: 0 auto; }
  a { color: #dc8100; text-decoration: none; }
  a:hover { color: #333; text-decoration: none; }
</style>

<article>
    <h1>We&rsquo;ll be back soon!</h1>
    <div>
        <p>Sorry for the inconvenience but we&rsquo;re performing some <strong>maintenance</strong> at the moment. If you need to you can always <a href="mailto:jrgavilanes@gmail.com">contact us</a>, otherwise we&rsquo;ll be back online shortly!</p>
        <p>&mdash; The Team</p>
    </div>
</article>
EOF



#Nginx configuración básico.
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

#Versión Landing Page para actualizar certificado.
cat << EOF > /etc/nginx/sites-available/$MI_DOMINIO-renove

# upstream docker_$MI_DOMINIO {

#     server localhost:$MI_DOCKER_PORT;

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

    #     proxy_pass http://docker_$MI_DOMINIO;

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

#Versión Docker para funcionar en producción.
cat << EOF > /etc/nginx/sites-available/$MI_DOMINIO

upstream docker_$MI_DOMINIO {

    server localhost:$MI_DOCKER_PORT;

}

server {

    listen 443 ssl;     

    server_name $MI_DOMINIO;

    ssl_certificate /etc/letsencrypt/live/$MI_DOMINIO/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$MI_DOMINIO/privkey.pem;

    root /var/www/$MI_DOMINIO;
    index index.html index.htm;


#    location / {

#        try_files \$uri \$uri/ =404;

#    }

    location / {

        proxy_pass http://docker_$MI_DOMINIO;

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
printf "\tañadir siguientes entradas: ( ejecutar todos los lunes a las 2:30 am )\n\n"
printf "\t30 2 * * 1 /home/janrax/renovar-certificado-"$MI_DOMINIO".sh"
echo $none

#Script renovación de certificado.
printf $green"\n\nGenerando archivo renovar-certificado-"$MI_DOMINIO".sh\n\n"$none
cat << EOF > "renovar-certificado-"$MI_DOMINIO".sh"
mv /etc/nginx/sites-available/$MI_DOMINIO /etc/nginx/sites-available/$MI_DOMINIO-backup
mv /etc/nginx/sites-available/$MI_DOMINIO-renove /etc/nginx/sites-available/$MI_DOMINIO

service nginx restart

/usr/local/sbin/certbot-auto renew >> /home/janrax/certificadoSSL.log
echo $(date) >> /home/janrax/certificadoSSL.log

mv /etc/nginx/sites-available/$MI_DOMINIO /etc/nginx/sites-available/$MI_DOMINIO-renove
mv /etc/nginx/sites-available/$MI_DOMINIO-backup /etc/nginx/sites-available/$MI_DOMINIO

service nginx restart

EOF


printf $green"\n\nFin del proceso\n\n"$none
