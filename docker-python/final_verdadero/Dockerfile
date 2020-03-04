FROM nginx:alpine

RUN apk update
RUN apk add certbot

RUN mkdir /app/html -p
RUN echo "hola" > /app/html/index.html

COPY ./default.https.conf /etc/nginx/conf.d/default.conf

WORKDIR /app

COPY . .

RUN tar -xzhvf letsencrypt_do.codekai.es.tar.gz && cp -r /app/letsencrypt /etc/letsencrypt

CMD ["python3", "start.py"]
