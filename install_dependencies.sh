#!/usr/bin/env bash
# install_dependencies.sh
# Script d'installation automatique des dépendances pour Youtube_MP3_Downloader
# Projet : https://github.com/Azhabel/Youtube_MP3_Downloader
# Gère les principales distributions : Debian/Ubuntu (apt), CentOS/RHEL/Fedora (yum/dnf), Arch (pacman)

set -euo pipefail

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"
DETECTED_PM=""
NEED_SUDO=false

# Fonction pour afficher les messages colorés
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# Fonction pour afficher une erreur et quitter
error_exit() {
    log_error "$1"
    exit 1
}

# Fonction pour exécuter une commande avec sudo si nécessaire
run_with_sudo() {
    local reason="$1"
    shift
    
    if [ "$NEED_SUDO" = true ]; then
        log_warning "Droits administrateur requis pour : $reason"
        sudo "$@"
    else
        "$@"
    fi
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour vérifier si un paquet est installé
is_package_installed() {
    local package="$1"
    case "$DETECTED_PM" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Détection du gestionnaire de paquets
detect_package_manager() {
    log_info "Détection du gestionnaire de paquets..."
    
    if command_exists apt; then
        DETECTED_PM="apt"
        NEED_SUDO=true
    elif command_exists dnf; then
        DETECTED_PM="dnf"
        NEED_SUDO=true
    elif command_exists yum; then
        DETECTED_PM="yum"
        NEED_SUDO=true
    elif command_exists pacman; then
        DETECTED_PM="pacman"
        NEED_SUDO=true
    else
        error_exit "Gestionnaire de paquets non reconnu. Distributions supportées :
  - Debian/Ubuntu (apt)
  - CentOS/RHEL/Fedora (yum/dnf)  
  - Arch Linux (pacman)

Veuillez installer manuellement les dépendances suivantes :
  - Node.js (version 16 ou supérieure)
  - npm
  - Python3 et python3-venv
  - curl
  - yt-dlp
Puis relancez ce script."
    fi
    
    log_success "Gestionnaire de paquets détecté : $DETECTED_PM"
}

# Fonction pour mettre à jour les dépôts
update_repositories() {
    log_info "Mise à jour des dépôts de paquets..."
    
    case "$DETECTED_PM" in
        apt)
            run_with_sudo "mise à jour des dépôts APT" apt update -y
            ;;
        dnf)
            run_with_sudo "mise à jour des dépôts DNF" dnf check-update -y || true
            ;;
        yum)
            run_with_sudo "mise à jour des dépôts YUM" yum check-update -y || true
            ;;
        pacman)
            run_with_sudo "mise à jour des dépôts Pacman" pacman -Sy --noconfirm
            ;;
    esac
    
    log_success "Dépôts mis à jour"
}

# Fonction pour installer les paquets de base
install_base_packages() {
    log_info "Installation des paquets de base..."
    
    local base_packages=()
    local missing_packages=()
    
    # Définir les paquets selon la distribution
    case "$DETECTED_PM" in
        apt)
            base_packages=(curl python3 python3-venv python3-pip build-essential)
            ;;
        dnf|yum)
            base_packages=(curl python3 python3-venv python3-pip gcc gcc-c++ make)
            ;;
        pacman)
            base_packages=(curl python python-pip base-devel)
            ;;
    esac
    
    # Vérifier quels paquets sont manquants
    for package in "${base_packages[@]}"; do
        if ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_success "Tous les paquets de base sont déjà installés"
        return 0
    fi
    
    log_info "Installation des paquets manquants : ${missing_packages[*]}"
    
    case "$DETECTED_PM" in
        apt)
            run_with_sudo "installation des paquets de base" apt install -y "${missing_packages[@]}"
            ;;
        dnf)
            run_with_sudo "installation des paquets de base" dnf install -y "${missing_packages[@]}"
            ;;
        yum)
            run_with_sudo "installation des paquets de base" yum install -y "${missing_packages[@]}"
            ;;
        pacman)
            run_with_sudo "installation des paquets de base" pacman -S --noconfirm "${missing_packages[@]}"
            ;;
    esac
    
    log_success "Paquets de base installés"
}

# Fonction pour installer Node.js
install_nodejs() {
    log_info "Vérification de Node.js..."
    
    # Vérifier si Node.js est déjà installé avec une version appropriée
    if command_exists node; then
        local node_version
        node_version=$(node -v | sed 's/v//')
        local major_version
        major_version=$(echo "$node_version" | cut -d. -f1)
        
        if [ "$major_version" -ge 16 ]; then
            log_success "Node.js v$node_version déjà installé"
            return 0
        else
            log_warning "Node.js v$node_version trop ancien (minimum requis : v16)"
        fi
    fi
    
    log_info "Installation de Node.js..."
    
    case "$DETECTED_PM" in
        apt)
            log_info "Ajout du dépôt NodeSource..."
            run_with_sudo "ajout du dépôt NodeSource" bash -c "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -"
            run_with_sudo "installation de Node.js" apt install -y nodejs
            ;;
        dnf)
            log_info "Ajout du dépôt NodeSource..."
            run_with_sudo "ajout du dépôt NodeSource" bash -c "curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -"
            run_with_sudo "installation de Node.js" dnf install -y nodejs
            ;;
        yum)
            log_info "Ajout du dépôt NodeSource..."
            run_with_sudo "ajout du dépôt NodeSource" bash -c "curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -"
            run_with_sudo "installation de Node.js" yum install -y nodejs
            ;;
        pacman)
            run_with_sudo "installation de Node.js" pacman -S --noconfirm nodejs npm
            ;;
    esac
    
    log_success "Node.js installé"
}

# Fonction pour vérifier les installations
verify_installations() {
    log_info "Vérification des installations..."
    
    # Vérifier Node.js
    if ! command_exists node; then
        error_exit "Node.js n'est pas installé correctement"
    fi
    local node_version
    node_version=$(node -v)
    log_success "Node.js $node_version installé"
    
    # Vérifier npm
    if ! command_exists npm; then
        error_exit "npm n'est pas installé correctement"
    fi
    local npm_version
    npm_version=$(npm -v)
    log_success "npm $npm_version installé"
    
    # Vérifier Python3
    if ! command_exists python3; then
        error_exit "Python3 n'est pas installé correctement"
    fi
    local python_version
    python_version=$(python3 --version)
    log_success "$python_version installé"
}

# Fonction pour créer l'environnement virtuel Python
setup_python_venv() {
    log_info "Configuration de l'environnement virtuel Python..."
    
    # Supprimer l'ancien environnement s'il existe
    if [ -d "$VENV_DIR" ]; then
        log_warning "Suppression de l'ancien environnement virtuel..."
        # Vérifier si le répertoire appartient à root
        if [ "$(stat -c '%U' "$VENV_DIR")" = "root" ]; then
            log_warning "L'ancien environnement virtuel appartient à root, suppression avec sudo..."
            run_with_sudo "suppression de l'ancien environnement virtuel créé par root" rm -rf "$VENV_DIR"
        else
            rm -rf "$VENV_DIR"
        fi
    fi
    
    # Créer le nouvel environnement virtuel
    log_info "Création de l'environnement virtuel..."
    python3 -m venv "$VENV_DIR"
    
    # Activer l'environnement virtuel
    log_info "Activation de l'environnement virtuel..."
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
    
    # Mettre à jour pip
    log_info "Mise à jour de pip..."
    pip install --upgrade pip
    
    # Installer yt-dlp
    log_info "Installation de yt-dlp..."
    pip install --upgrade yt-dlp
    
    # Vérifier yt-dlp
    if ! command_exists yt-dlp; then
        error_exit "yt-dlp n'est pas installé correctement"
    fi
    local ytdlp_version
    ytdlp_version=$(yt-dlp --version)
    log_success "yt-dlp $ytdlp_version installé"
    
    # Désactiver l'environnement virtuel
    deactivate
    
    log_success "Environnement virtuel Python configuré"
}

# Fonction pour installer les dépendances npm
install_npm_dependencies() {
    log_info "Installation des dépendances npm du projet..."
    
    if [ ! -f "$SCRIPT_DIR/package.json" ]; then
        log_warning "Fichier package.json non trouvé. Utilisation de la configuration par défaut du projet..."
        cat > "$SCRIPT_DIR/package.json" << 'EOF'
{
  "name": "youtube-mp3-downloader",
  "version": "1.0.0",
  "description": "Téléchargeur MP3 depuis YouTube avec yt-dlp",
  "main": "dl.js",
  "scripts": {
    "start": "node dl.js",
    "download": "node download.js"
  },
  "dependencies": {
    "ytdl-core": "^4.11.5",
    "ffmpeg-static": "^5.2.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/Azhabel/Youtube_MP3_Downloader.git"
  },
  "keywords": ["youtube", "mp3", "downloader", "yt-dlp"],
  "author": "Azhabel",
  "license": "MIT"
}
EOF
    fi
    
    # Installer les dépendances npm
    cd "$SCRIPT_DIR"
    npm install
    
    log_success "Dépendances npm du projet installées"
}

# Fonction pour créer un script d'activation
create_activation_script() {
    log_info "Création du script d'activation..."
    
    cat > "$SCRIPT_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Script d'activation de l'environnement de développement
# Youtube_MP3_Downloader - https://github.com/Azhabel/Youtube_MP3_Downloader

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Environnement virtuel non trouvé."
    echo "💡 Exécutez ./install_dependencies.sh pour configurer le projet"
    exit 1
fi

echo "🔧 Activation de l'environnement virtuel Python..."
source "$VENV_DIR/bin/activate"

echo "✅ Environnement Youtube_MP3_Downloader activé !"
echo ""
echo "🎵 Commandes disponibles :"
echo "   ./download.sh     # Télécharge les URLs depuis urls.txt"
echo "   npm start         # Lance l'application Node.js"
echo "   yt-dlp --version  # Vérifier la version de yt-dlp"
echo ""
echo "💡 Pour désactiver l'environnement, tapez 'deactivate'"

# Lancer un nouveau shell avec l'environnement activé
exec bash
EOF
    
    chmod +x "$SCRIPT_DIR/activate.sh"
    log_success "Script d'activation créé : ./activate.sh"
}

# Fonction principale
main() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "  Youtube_MP3_Downloader - Installation"
    echo "  Téléchargeur MP3 depuis YouTube"
    echo "================================================"
    echo -e "${NC}"
    
    # Vérifier si nous sommes dans le bon répertoire (présence des fichiers du projet)
    if [ ! -f "$SCRIPT_DIR/$(basename "$0")" ] || [ ! -f "$SCRIPT_DIR/download.sh" ]; then
        error_exit "Veuillez exécuter ce script depuis le répertoire Youtube_MP3_Downloader
💡 Clonez le projet avec : git clone https://github.com/Azhabel/Youtube_MP3_Downloader.git"
    fi
    
    detect_package_manager
    update_repositories
    install_base_packages
    install_nodejs
    verify_installations
    setup_python_venv
    install_npm_dependencies
    create_activation_script
    
    echo -e "${GREEN}"
    echo "================================================"
    echo "  ✅ Youtube_MP3_Downloader prêt à l'emploi !"
    echo "================================================"
    echo -e "${NC}"
    echo ""
    echo "🚀 Pour utiliser le téléchargeur MP3 :"
    echo "   1. Ajoutez vos URLs YouTube dans urls.txt"
    echo "   2. Lancez : ./download.sh"
    echo ""
    echo "🔧 Pour le développement :"
    echo "   ./activate.sh     # Active l'environnement de développement"
    echo "   npm start         # Lance l'application Node.js"
    echo ""
    echo "📝 Fichiers générés :"
    echo "   - venv/           # Environnement virtuel Python avec yt-dlp"
    echo "   - activate.sh     # Script d'activation pour le développement"
    echo "   - downloads/      # Dossier de destination des MP3 (sera créé)"
    echo ""
    echo "💡 Astuce : Si yt-dlp pose problème, mettez-le à jour avec :"
    echo "   source venv/bin/activate && pip install -U yt-dlp"
}

# Piège pour nettoyer en cas d'interruption
trap 'echo -e "\n${RED}❌ Installation de Youtube_MP3_Downloader interrompue${NC}"; exit 1' INT TERM

# Exécuter le script principal
main "$@"
