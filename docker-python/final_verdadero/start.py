import os
import time

os.system("nginx")

while True:
    os.system("certbot renew --force-renewal")
    time.sleep(3600*12)
