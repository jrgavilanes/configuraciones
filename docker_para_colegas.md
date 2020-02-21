# Docker para colegas

## Instalación

```
$ sudo apt-get install docker.io docker-compose

$ sudo groupadd docker
$ sudo usermod -aG docker $USER

s sudo reboot
```


## Comandos Básicos
```bash
docker run debian ping google.es

docker run -it debian /bin/bash

docker images
docker ps -a

docker create debian # devuelve container_id

docker start <container_id>
docker logs <container_id>
docker stop <container_id>
docker kill <container_id>

docker start -a <container_id>

docker exec -it <container_id> /bin/bash

docker system prune -a
```

## Dockerfile
```
FROM debian
RUN apt update
CMD ["ping", "google.es"]
```

```
docker build .
docker build -t jrgavilanes/proyecto:version .
```

### Imagen desde contenedor ( No recomendado)

docker commit -c 'CMD ["ping", "google.es"]' <container_id>


### Redireccionando puerto
```
docker run -p 5000:8080 <imagen_id>
```

Ejemplo de guay:
```
# Dockerfile
FROM debian
RUN apt update
RUN apt install -y python3 python3-pip
CMD ["python3", "-m", "http.server"]
```

Rúlalo
```
docker -t juanra build .
docker run -p 5000:8000 juanra

curl localhost:5000
```
