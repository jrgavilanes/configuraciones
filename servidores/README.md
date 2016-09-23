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

### Pasos a seguir
- $ wget https://raw.githubusercontent.com/jrgavilanes/configuraciones/master/servidores/create_domain.sh
- $ sudo bash create_domain.sh


