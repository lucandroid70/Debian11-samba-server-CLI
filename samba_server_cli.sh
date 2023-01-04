#!/bin/bash


sudo apt update
sudo apt upgrade
sudo apt install bash-completion -y
sudo apt install samba samba-common samba-client -y

sudo systemctl enable smbd.service
sudo systemctl start smbd.service 

sudo systemctl enable nmbd.service
sudo systemctl start nmbd.service




sudo cp /etc/samba/smb.conf /etc/samba/_smb.conf

###################### CREATED By Luca S. ITA Ministry of Defense employee UTENTI ######################### 

read -p "Inserisci il nome dell'utente 1 samba per la cartella privata server samba, successivamente inserisci 2 volte la password utente e 2 volte la password samba che possono essere uguali " utente1

sudo useradd -M -s /sbin/nologin $utente1
sudo passwd $utente1
sudo smbpasswd -a $utente1
sudo smbpasswd -e $utente1
sudo groupadd sambashare
sudo usermod -a -G sambashare $utente1


read -p "Inserisci il nome dell'utente 2 samba per la cartella privata server samba, successivamente inserisci 2 volte la password utente e 2 volte la password samba che possono essere uguali " utente2

sudo useradd -M -s /sbin/nologin $utente2
sudo passwd $utente2
sudo smbpasswd -a $utente2
sudo smbpasswd -e $utente2
sudo groupadd sambashare
sudo usermod -a -G sambashare $utente2





###################### CREATED By Luca S. ITA Ministry of Defense employee UTENTI FINE ######################### 



###################### CREATED By Luca S. ITA Ministry of Defense employee DIRECTORY e attributi  FINE ######################### 

# prompt user for virtual host name
read -p "Inserisci il nome della PRIMA cartella privata server samba " directory1

# create virtual host directory
sudo mkdir -p /srv/secure/$directory1
sudo chgrp -R sambashare /srv/secure/$directory1
sudo chmod -R 2770 /srv/secure/$directory1
sudo chown -R $utente1: /srv/secure/$directory1

sudo setfacl -R -m "g:sambashare:rwx" /srv/secure/$directory1

# prompt user for virtual host name
read -p "Inserisci il nome della SECONDA cartella privata server samba " directory2

# create virtual host directory
sudo mkdir -p /srv/secure/$directory2
sudo chgrp -R sambashare /srv/secure/$directory2
sudo chmod -R 2770 /srv/secure/$directory2
sudo chown -R $utente2:sambashare /srv/secure/$directory2
sudo setfacl -R -m "g:sambashare:rwx" /srv/secure/$directory2




read -p "Inserisci il nome della cartella condivisa scambio server samba --ATTENZIONE TUTTI POSSONO VEDERE IL CONTENUTO-- " scambio21


sudo mkdir -p /srv/all/$scambio21
sudo chmod -R 2775 /srv/all/$scambio21
sudo setfacl -R -m "u:nobody:rwx" /srv/all/$scambio21
#sudo chgrp -R smbshare /srv/all/$scambio21


#sudo chmod -R 2777 /srv/all/$scambio21
#sudo chown -R nobody:nobody /srv/all/$scambio21
#sudo chcon -t samba_share_t -R /srv/all/$scambio21
#sudo setfacl -R -m "u:nobody:rwx" /srv/all/$scambio21
#sudo chgrp -R smbshare /public



###################### CREATED By Luca S. ITA Ministry of Defense employee DIRECTORY e attributi  FINE ######################### 




###################### CREATED By Luca S. ITA Ministry of Defense employee ######################### 




cat >> /etc/samba/smb.conf << EOF
[$directory1]
workgroup = WORKGROUP
server string = Samba Server %v
netbios name = smbshared 
security = user
map to guest = bad user
dns proxy = no
path = /srv/secure/$directory1
valid users = @sambashare
guest ok = no
writable = yes
browsable = yes
# Anonymous shared 


[$directory2]
workgroup = WORKGROUP
server string = Samba Server %v
netbios name = smbshared 
security = user
map to guest = bad user
dns proxy = no
path = /srv/secure/$directory2
valid users = @sambashare
guest ok = no
writable = yes
browsable = yes
# Anonymous shared 

[Scambio]
workgroup = WORKGROUP
server string = Samba Server %v
netbios name = smbshared 
path = /srv/all/$scambio21
browsable =yes
writable = yes
guest ok = yes
read only = no
guest only = yes
force create mode = 775
force directory mode = 775
EOF




sudo systemctl enable smbd.service
sudo systemctl start smbd.service 

sudo systemctl enable nmbd.service
sudo systemctl start nmbd.service
