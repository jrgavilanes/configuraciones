import os
import time

os.system("nginx")

while True:
    os.system("certbot renew")
    time.sleep(3600*12)