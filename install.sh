#!/data/data/com.termux/files/usr/bin/bash
# ════════════════════════════════════════════════════════════════
#  Deku-Analyse - Installateur automatique
#  Prépare tout ce qu'il faut pour lancer deku-analyse.sh directement
# ════════════════════════════════════════════════════════════════

set -u

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Installation automatique de Deku-Analyse${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"

# ── 1. Vérifier qu'on est bien dans Termux ─────────────────────────
if [ ! -d "/data/data/com.termux/files/usr" ]; then
    warn "Ce script est conçu pour Termux sur Android."
    warn "Il peut continuer sur un Linux classique, mais certaines"
    warn "fonctionnalités (batterie, capteurs) resteront indisponibles."
    echo ""
fi

IS_TERMUX=false
command -v pkg >/dev/null 2>&1 && IS_TERMUX=true

# ── 2. Mise à jour des paquets + dépendances ────────────────────────
if [ "$IS_TERMUX" = true ]; then
    info "Mise à jour des paquets Termux..."
    pkg update -y >/dev/null 2>&1
    success "Paquets à jour"

    info "Installation des dépendances obligatoires..."
    pkg install -y bash coreutils procps >/dev/null 2>&1
    success "Dépendances de base installées"

    info "Installation des dépendances optionnelles (réseau, capteurs)..."
    pkg install -y termux-api iproute2 net-tools dnsutils >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        success "Dépendances optionnelles installées"
    else
        warn "Certaines dépendances optionnelles n'ont pas pu être installées"
        warn "(le script fonctionnera quand même, avec des fonctions limitées)"
    fi
else
    warn "Commande 'pkg' introuvable - installation des dépendances ignorée."
    warn "Installez manuellement : ping, df, awk, grep, sed"
fi
echo ""

# ── 3. Vérifier l'app compagnon Termux:API ──────────────────────────
info "Vérification de l'app Termux:API (nécessaire pour la batterie)..."
API_OK=false
if command -v termux-battery-status >/dev/null 2>&1; then
    TEST_JSON=$(timeout 5 termux-battery-status 2>/dev/null)
    if echo "$TEST_JSON" | grep -q '"percentage"'; then
        API_OK=true
    fi
fi

if [ "$API_OK" = true ]; then
    success "Termux:API fonctionne correctement"
else
    warn "L'app Termux:API n'est pas installée ou n'a pas les permissions nécessaires"
    echo -e "${YELLOW}    → Sans elle, les infos batterie utiliseront un fallback moins précis${NC}"
    echo -e "${YELLOW}    → Installez-la depuis F-Droid (recommandé, reste synchronisée avec le paquet Termux):${NC}"
    echo -e "${CYAN}       https://f-droid.org/packages/com.termux.api/${NC}"
    if command -v termux-open-url >/dev/null 2>&1; then
        echo -ne "${YELLOW}    Ouvrir la page de téléchargement maintenant ? (o/n) : ${NC}"
        read -r OPEN_LINK
        if [ "$OPEN_LINK" = "o" ] || [ "$OPEN_LINK" = "O" ]; then
            termux-open-url "https://f-droid.org/packages/com.termux.api/" 2>/dev/null
        fi
    fi
fi
echo ""

# ── 4. Permission de stockage (accès /sdcard pour le stockage interne) ──
if [ "$IS_TERMUX" = true ] && [ ! -d "$HOME/storage" ]; then
    warn "Accès au stockage partagé non configuré (utile pour lire /sdcard)"
    echo -ne "${YELLOW}    Configurer maintenant avec termux-setup-storage ? (o/n) : ${NC}"
    read -r SETUP_STORAGE
    if [ "$SETUP_STORAGE" = "o" ] || [ "$SETUP_STORAGE" = "O" ]; then
        termux-setup-storage
        success "Demande de permission envoyée (acceptez la popup Android)"
    fi
    echo ""
fi

# ── 5. Dossiers du projet ───────────────────────────────────────────
info "Création des dossiers reports/ et logs/..."
mkdir -p "$SCRIPT_DIR/reports" "$SCRIPT_DIR/logs"
success "Dossiers créés"
echo ""

# ── 6. Droits d'exécution ───────────────────────────────────────────
info "Attribution des droits d'exécution..."
chmod +x "$SCRIPT_DIR/deku-analyse.sh" 2>/dev/null
success "deku-analyse.sh est exécutable"
echo ""

# ── 7. Fichier de configuration par défaut ──────────────────────────
CONFIG_FILE="$SCRIPT_DIR/.deku-config"
if [ ! -f "$CONFIG_FILE" ]; then
    info "Création du fichier de configuration par défaut..."
    {
        echo "# Deku-Analyse - Configuration des seuils"
        echo "BATTERY_LOW_THRESHOLD=20"
        echo "RAM_HIGH_THRESHOLD=85"
        echo "STORAGE_HIGH_THRESHOLD=90"
        echo "CPU_TEMP_WARN=50"
        echo "CPU_TEMP_HIGH=70"
    } > "$CONFIG_FILE"
    success "Configuration créée ($CONFIG_FILE)"
else
    success "Configuration existante conservée ($CONFIG_FILE)"
fi
echo ""

# ── 8. Raccourci de lancement (optionnel) ───────────────────────────
if [ "$IS_TERMUX" = true ]; then
    BIN_DIR="$PREFIX/bin"
    if [ -d "$BIN_DIR" ] && [ -w "$BIN_DIR" ]; then
        echo -ne "${YELLOW}Créer la commande globale 'deku-analyse' (utilisable depuis n'importe où) ? (o/n) : ${NC}"
        read -r CREATE_LINK
        if [ "$CREATE_LINK" = "o" ] || [ "$CREATE_LINK" = "O" ]; then
            ln -sf "$SCRIPT_DIR/deku-analyse.sh" "$BIN_DIR/deku-analyse"
            chmod +x "$BIN_DIR/deku-analyse"
            success "Commande 'deku-analyse' disponible partout dans Termux"
        fi
    fi
fi
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Installation terminée !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "Lancez l'outil avec :"
echo -e "  ${CYAN}./deku-analyse.sh${NC}"
if [ -e "${PREFIX:-}/bin/deku-analyse" ]; then
    echo -e "  ou, depuis n'importe où : ${CYAN}deku-analyse${NC}"
fi
echo ""
