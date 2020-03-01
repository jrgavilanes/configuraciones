FROM nginx:1.17-alpine

RUN apk update
RUN apk add certbot

RUN mkdir /app/static -p
RUN echo "PAGINA INICIAL" > /app/static/index.html

COPY ./default.conf /etc/nginx/conf.d/default.conf
RUN nginx &

RUN certbot certonly -a webroot --webroot-path=/app/static -d docker.codekai.es --non-interactive --agree-tos -m janrax@yopmail.com
COPY ./default.https.conf /etc/nginx/conf.d/default.conf

RUN nginx -s stop

WORKDIR /app

COPY ./start_container.py .

CMD ["python3", "start_container.py"]



