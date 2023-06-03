#!/bin/bash

# Assicurati di eseguire lo script con privilegi di root
if [[ $EUID -ne 0 ]]; then
   echo "Questo script deve essere eseguito con privilegi di root."
   exit 1
fi

# Aggiorna il sistema
echo "Aggiorno il sistema..."
sudo apt update
sudo apt upgrade -y

# Installa il pacchetto bash-completion
echo "Installo il pacchetto bash-completion..."
sudo apt install bash-completion -y

# Installa Samba
echo "Installo Samba..."
sudo apt install samba samba-common samba-client -y

# Abilita e avvia i servizi Samba
echo "Avvio i servizi Samba..."
sudo systemctl enable smbd.service
sudo systemctl start smbd.service
sudo systemctl enable nmbd.service
sudo systemctl start nmbd.service

# Effettua il backup del file di configurazione di Samba
echo "Backup del file di configurazione di Samba..."
sudo cp /etc/samba/smb.conf /etc/samba/_smb.conf

# Crea gli utenti e le cartelle condivise
echo "Creazione utenti e cartelle condivise..."

# Funzione per la creazione di utenti e cartelle
create_user_and_share() {
    local username=$1
    local password=$2
    local directory=$3

    # Crea l'utente senza accesso shell
    sudo useradd -M -s /sbin/nologin $username
    sudo passwd $username

    # Imposta la password Samba per l'utente
    sudo smbpasswd -a $username
    sudo smbpasswd -e $username

    # Aggiungi l'utente al gruppo sambashare
    sudo groupadd sambashare
    sudo usermod -a -G sambashare $username

    # Crea la cartella condivisa
    sudo mkdir -p /srv/secure/$directory
    sudo chgrp -R sambashare /srv/secure/$directory
    sudo chmod -R 2770 /srv/secure/$directory
    sudo chown -R $username: /srv/secure/$directory
    sudo setfacl -R -m "g:sambashare:rwx" /srv/secure/$directory
}

# Lettura del primo utente e cartella
read -p "Inserisci il nome dell'utente 1 per la cartella privata server Samba, successivamente inserisci la password utente e la password Samba che possono essere uguali: " utente1
read -p "Inserisci il nome della cartella privata server Samba per l'utente 1: " directory1

# Creazione del primo utente e cartella condivisa
create_user_and_share $utente1 $utente1 $directory1

# Lettura del secondo utente e cartella
read -p "Inserisci il nome dell'utente 2 per la cartella privata server Samba, successivamente inserisci la password utente e la password Samba che possono essere uguali: " utente2
read -p "Inserisci il nome della cartella privata server Samba per l'utente 2: " directory2

# Creazione del secondo utente e cartella condivisa
create_user_and_share $utente2 $utente2 $directory2

# Creazione della cartella condivisa di scambio
read -p "Inserisci il nome della cartella condivisa per lo scambio sul server Samba (Attenzione: tutti possono accedere): " scambio21

sudo mkdir -p /srv/all/$scambio21
sudo chmod -R 2775 /srv/all/$scambio21
sudo setfacl -R -m "u:nobody:rwx" /srv/all/$scambio21

# Aggiunta delle configurazioni al file smb.conf
echo "Aggiunta delle configurazioni al file smb.conf..."
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

[Scambio]
   workgroup = WORKGROUP
   server string = Samba Server %v
   netbios name = smbshared 
   path = /srv/all/$scambio21
   browsable = yes
   writable = yes
   guest ok = yes
   read only = no
   guest only = yes
   force create mode = 775
   force directory mode = 775
EOF

# Riavvia i servizi Samba
echo "Riavvio i servizi Samba..."
sudo systemctl restart smbd.service
sudo systemctl restart nmbd.service

echo "Lo script è stato completato con successo."
