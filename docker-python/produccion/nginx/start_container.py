import os
import time

os.system("nginx") # Arranca el proxy inverso

while True:
    os.system("certbot renew")
    time.sleep(3600*24) # Intenta renovar cada 24 horas.
