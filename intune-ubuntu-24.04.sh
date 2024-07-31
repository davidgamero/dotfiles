# based on https://www.jdegoeij.com/posts/intune-ubuntu-24-04/

# set up sources
SOURCES_FILE=/etc/apt/sources.list.d
if ! grep -q "Suites: mantic" $SOURCES_FILE; then
  echo "adding mantic apt source"
  echo "Types: deb
URIs: http://nl.archive.ubuntu.com/ubuntu/
Suites: mantic
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: mantic-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" >> SOURCES_FILE
else
  echo "mantic source found, skipping..."
fi
if ! grep -q "Suites: nuble" $SOURCES_FILE; then
  echo "adding noble apt source"
  echo "Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" >> SOURCES_FILE
else
  echo "noble source found, skipping..."
fi

# Install edge
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo rm microsoft.gpg
sudo apt update && sudo apt install microsoft-edge-stable

# Install Intune
sudo apt install openjdk-11-jre libicu72 libjavascriptcoregtk-4.0-18 libwebkit2gtk-4.0-37

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list'
sudo rm microsoft.gpg
sudo apt update
sudo apt install intune-portal

