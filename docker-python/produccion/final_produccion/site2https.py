import os

resultado = os.system("certbot certonly -a webroot --webroot-path=/app/html -d d.codekai.es --non-interactive --agree-tos -m janrax@yopmail.com")
if resultado == 0:
    os.system("cp /app/default.https.conf /etc/nginx/conf.d/default.conf")
    os.system("nginx -s reload")
    os.system("mv /app/start2.py /app/start.py")
    print("Ya está convertido a https. Necesitas reiniciar el contenedor para autorenovar el certificado ssl.")
else:
    print("Algo ha ido mal al requerir el certificado ssl.")

