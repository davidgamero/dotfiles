#!/bin/sh
# based on https://www.jdegoeij.com/posts/intune-ubuntu-24-04/

# set up sources
SOURCES_FILE=/etc/apt/sources.list.d/ubuntu.sources
if ! grep -q "Suites: mantic" $SOURCES_FILE; then
  echo "mantic source not found in $SOURCES_FILE"
  echo "adding mantic apt source to $SOURCES_FILE"
  sudo echo "
Types: deb
URIs: http://nl.archive.ubuntu.com/ubuntu/
Suites: mantic
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: mantic-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
" >> $SOURCES_FILE
 if ! grep -q "Suites: mantic" $SOURCES_FILE; then
   echo "failed to add mantic sources"
   exit
 else
   echo "successfully added mantic sources"
 fi
else
  echo "mantic source found"
fi
if ! grep -q "Suites: noble" $SOURCES_FILE; then
  echo "noble source not found in $SOURCES_FILE"
  echo "adding noble apt source to $SOURCES_FILE"
  sudo echo "
Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
" >> $SOURCES_FILE
else
  echo "noble source found"
fi

sudo apt update

# Install edge
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
sudo rm microsoft.gpg
sudo apt update && sudo apt install microsoft-edge-stable

# Install Intune
sudo apt install openjdk-11-jre libicu72 libjavascriptcoregtk-4.0-18 libwebkit2gtk-4.0-37

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list'
sudo rm microsoft.gpg
sudo apt update

# azure vpn
sudo apt-get install microsoft-azurevpnclient

# GCM
wget https://aka.ms/gcm/linux-install-source.sh -O ~/Downloads/git-credential-manaager-install.sh
chmod +x ~/Downloads/git-credential-manaager-install.sh
~/Downloads/git-credential-manaager-install.sh
git config --global credential.azreposCredentialType oauth
git-credential-manager configure
sudo apt install intune-portal

