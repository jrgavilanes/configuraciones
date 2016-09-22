#!/bin/bash
# ******************************************************************
# ** Description : Script Initial Configuration for Ubuntu (16.04)
# ** File        : ubuntu_first_install.sh
# ** Version     : 1.0
# ** Maintainer  : Juan R. Gavilanes
# ** Date        : 2016-09-22
# ******************************************************************


#Styles
red=$( echo -e "\033[1;31;40m" )
green=$( echo -e "\033[1;32;40m" )
none=$( echo -e "\033[0m" )

# Check if you are using your own user not root.
if [ $USER == "root" ]
  then 
  
  echo $red
  echo "Please don't use the real root user."
  echo "Create your own and make it big:"
  printf "\n\t\$ adduser YOUR-USER\n\t\$ gpasswd -a YOUR-USER sudo\n\t\$ sudo su YOUR-USER\n\n" 
  echo "Then from your local computer, create a rsa key ( if you don't have one ):"
  printf "\n\t\$ ssh-keygen\n\n" 
  echo "And finally, also from your local computer, transfer the key to this server"
  printf "\n\t\$ ssh-copy-id YOUR-USER@SERVER_IP_ADDRESS\n\n" 
  echo $none

  exit
fi

# Update Repositories and installing software.
echo $green"Updating the repositories and installing some nice programs ..."$none

sudo apt-get update
sudo apt-get install htop ntp nginx fail2ban wget -y

# Docker
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# The following source.list is only for Ubuntu 16.04 
# ( see sources for other versions at https://docs.docker.com/engine/installation/linux/ubuntulinux/ )
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -y docker-engine docker-compose

# Set the firewall. Open only SSH, HTTP and SSL ports services
echo $green"Preparing the firewall ..."$none

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw show added
sudo ufw enable
sudo ufw status

# Set the Time Zone
echo $green"Getting your Time Zone ..."$none
sudo dpkg-reconfigure tzdata

# Set the Swap File if does not exist.
if [ ! -f /swapfile ]; then

    echo $green"Creating SWAPFILE ..."$none

    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
fi

# Final Advices
echo $red

printf "\nRemember to disable ssh access to root user, and allow to connect only with ssh-key.\n\n"
printf "\t\$ sudo vi /etc/ssh/sshd_config\n"
printf "\t\t PermitRootLogin no\n"
printf "\t\t PasswordAuthentication no\n\n"
printf "\t\$ sudo service ssh restart\n\n"

echo $none