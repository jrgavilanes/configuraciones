# Renombrar cosas de archivos.

sed -i "s/do.codekai.es/nuevo.com/g" Dockerfile default.https.conf


# Docker
docker build -t janrax/nginxssl .


docker run -p 80:80 -p 443:443 janrax/nginxssl

docker ps

docker exec -it <contenedor> sh


# scp a saco

scp -r * root@do.codekai.es:.

# comprimir con links simbolicos
tar -czvf name-of-archive.tar.gz /path/to/directory-or-file
# descomprime en :
tar -xzvhf archive.tar.gz -C /tmp
# ver tar.gz
tar -tzvf archive.tar.gz


