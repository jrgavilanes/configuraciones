# jrgWare Platform ( Quick Reference )

[Documento detallado](https://docs.google.com/document/d/1V-QEbGHa6ZhkpXp_-GwKbyHBLo551QryOeY2M-qVWM0/edit?usp=sharing)

## 1.- Creación nuevo Droplet Digital Ocean

### Pasos a seguir
- Crear Droplet ( sin clavess ssh, para recibir password por email )
- Asociar NUEVO-DOMINIO con IP del nuevo Droplet
 - Area Networking. Añadir record A -> IP
 - Ping Domain, debe resolver.
- Accedemos al droplet desde su consola web.
 - Entramos con root ( password en nuestro email )
 - Creamos usuario y lo escalamos.
   - $ adduser YOUR-USER
   - $ gpasswd -a YOUR-USER sudo
   - $ sudo su YOUR-USER
- Accedemos al droplet desde nuestro ordenador local.
 - $ ssh-keygen ( si no tenemos ssh-key creada )
 - $ ssh-copy-id YOUR-USER@NUEVO-DOMINIO
 - $ ssh NUEVO-DOMINIO
- Instalamos Configuración Básica
 - $ wget https://raw.githubusercontent.com/jrgavilanes/configuraciones/master/servidores/ubuntu_first_install.sh
 - $ bash ubuntu_first_install.sh


## 2.- Creación nueva Aplicación en Droplet

### Pasos iniciales
- $ wget https://raw.githubusercontent.com/jrgavilanes/configuraciones/master/servidores/create_domain.sh
- $ sudo bash create_domain.sh

### Configurar Nginx como proxy-inverso a Docker.
- Editamos nuevo archivo generado en /etc/nginx/sites-available
 - Descomentamos primer bloque (upstream docker_...)
   - Configuramos el puerto correcto por el que el contenedor escuchará ( defecto 3000 )
 - Comentamos el primer bloque location /
 - Descomentamos el segundo ( contendrá la directiva __proxy_pass__ )
  
### Ejemplo caso de Uso: Ejecutar dos instancias Docker de RStudio Server ([detalles imagen](https://github.com/rocker-org/rocker/wiki/Using-the-RStudio-image)) en un droplet

#### 1.- Configurar los subdominios del dominio jrgware: 
rstudio1.jrgware.es y rstudio2.jrgware.es apuntan a la dirección IP del droplet.

#### 2.- Creamos Contenedores Docker
```
$ sudo docker run -d -p 3000:8787 --name=rstudio1 -e USER=<username> -e PASSWORD=<password> rocker/rstudio
$ sudo docker run -d -p 4000:8787 --name=rstudio2 -e USER=<username> -e PASSWORD=<password> rocker/rstudio 

```
#### 3.- Descargamos script create_domain.sh.
Lo ejecutaremos dos veces, indicando el nombre de cada dominio.
```
$ wget https://raw.githubusercontent.com/jrgavilanes/configuraciones/master/servidores/create_domain.sh
$ sudo bash create_domain.sh
  (rstudio1.jrgware.es)
$ sudo bash create_domain.sh
  (rstudio2.jrgware.es)

```
#### 4.- Actualizamos configuración nginx para que apunten al contenedor docker.

$sudo nano /etc/nginx/sites-available/rstudio1.jrgware.es
```
upstream docker_rstudio1.jrgware.es {

    server localhost:3000;

}
...

#location / {

#   try_files $uri $uri/ =404;

#}

location / {

    proxy_pass http://docker_rstudio1.jrgware.es;

}
...

```

$sudo nano /etc/nginx/sites-available/rstudio2.jrgware.es
```
upstream docker_rstudio2.jrgware.es {

    server localhost:3000;

}
...

#location / {

#   try_files $uri $uri/ =404;

#}

location / {

    proxy_pass http://docker_rstudio2.jrgware.es;

}
...

```
Reiniciamos Nginx
```
$ sudo service nginx restart
```

#### 5.- Iniciamos automáticamente contenedores al iniciar el sistema (offtopic)

file: /etc/rc.local
```
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.


docker start rstudio1
docker start rstudio2

exit 0
```

