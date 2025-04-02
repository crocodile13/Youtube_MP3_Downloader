#!/bin/bash

# Vérifier si l'utilisateur a les droits d'administrateur
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script nécessite des privilèges root. Veuillez l'exécuter avec sudo."
  exit 1
fi

echo "Mise à jour des dépôts et installation des prérequis..."

# Mettre à jour les dépôts de paquets
apt update -y

# Installer Node.js et npm
echo "Installation de Node.js et npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - # Installe Node.js v18
apt install -y nodejs

# Vérifier que Node.js et npm sont bien installés
node -v
npm -v

# Installer Python3 et pip3 si nécessaire
echo "Installation de Python3 et pip3..."
apt install -y python3 python3-pip

# Vérification de l'installation de Python3
python3 --version
pip3 --version

# Installer yt-dlp via pip
echo "Installation de yt-dlp (via pip)..."
pip3 install -U yt-dlp

# Vérification de l'installation de yt-dlp
yt-dlp --version

# Installer les paquets nécessaires pour le projet Node.js
echo "Installation des dépendances npm..."
npm install

# Vérification des installations
echo "Vérification de l'installation..."
yt-dlp --version
echo "L'installation est terminée avec succès !"

