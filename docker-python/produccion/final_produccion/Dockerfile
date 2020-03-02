FROM nginx:alpine
RUN apk update
RUN apk add certbot

RUN mkdir /app/html -p
RUN echo "hola" > /app/html/index.html

COPY ./default.conf /etc/nginx/conf.d/default.conf

WORKDIR /app

COPY . .

CMD ["python3", "start.py"]