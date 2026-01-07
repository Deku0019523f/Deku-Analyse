#!/data/data/com.termux/files/usr/bin/bash

# ════════════════════════════════════════════════════════════════
#  DEKU-ANALYSE v2.1 - Outil de diagnostic et détection surveillance
#  Auteur: DarkDeku225
#  Telegram: t.me/DarkDeku225
# ════════════════════════════════════════════════════════════════

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Configuration
VERSION="2.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
LOGS_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$SCRIPT_DIR/.deku-config"

# Variables globales
QUIET_MODE=false
PING_RESULT=""
PING_TIME=""

# ════════════════════════════════════════════════════════════════
#  FONCTIONS UTILITAIRES
# ════════════════════════════════════════════════════════════════

info() {
    [ "$QUIET_MODE" = false ] && echo -e "${BLUE}[*]${NC} $1"
}

success() {
    [ "$QUIET_MODE" = false ] && echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

debug() {
    [ "$QUIET_MODE" = false ] && echo -e "${GRAY}[DEBUG]${NC} $1"
}

init_directories() {
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    mkdir -p "$LOGS_DIR" 2>/dev/null
}

check_dependencies() {
    local missing=()
    local optional_missing=()

    for cmd in ping df awk grep sed; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    for cmd in termux-battery-status nslookup ip netstat; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            optional_missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        error "Dépendances manquantes: ${missing[*]}"
        echo -e "${YELLOW}Installez avec: pkg install ${missing[*]}${NC}"
        return 1
    fi

    if [ ${#optional_missing[@]} -gt 0 ] && [ "$QUIET_MODE" = false ]; then
        warn "Dépendances optionnelles manquantes: ${optional_missing[*]}"
        echo -e "${GRAY}Certaines fonctionnalités seront limitées${NC}"
    fi

    return 0
}

show_banner() {
    [ "$QUIET_MODE" = true ] && return
    clear
    echo -e "${CYAN}"
    cat << "EOF"
 ____       _          
|  _ \  ___| | ___   _ 
| | | |/ _ \ |/ / | | |
| |_| |  __/   <| |_| |
|____/ \___|_|\_\__,_|

    _                _                 
   / \   _ __   __ _| |_   _ ___  ___ 
  / _ \ | '_ \ / _` | | | | / __|/ _  / ___ \| | | | (_| | | |_| \__ \  __/
/_/   \_\_| |_|\__,_|_|\__, |___/\___|
                       |___/           
EOF
    echo -e "        Deku-Analyse v${VERSION}"
    echo -e "${NC}"
}

show_menu() {
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[1]${NC} Checkout Complet"
    echo -e "${GREEN}[2]${NC} État Rapide de l'appareil"
    echo -e "${GREEN}[3]${NC} Mode Monitoring (Log continu)"
    echo -e "${GREEN}[4]${NC} Analyse de Sécurité Avancée"
    echo -e "${GREEN}[5]${NC} Test Réseau Détaillé"
    echo -e "${GREEN}[6]${NC} Historique des Rapports"
    echo -e "${GREEN}[7]${NC} Configuration"
    echo -e "${RED}[8]${NC} 🔴 Détection Surveillance / Écoute / Piratage"
    echo -e "${RED}[0]${NC} Quitter"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -ne "${YELLOW}CHOOSE AN OPTION : ${NC}"
}

show_signature() {
    [ "$QUIET_MODE" = true ] && return
    echo -e "\n${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Outil : ${WHITE}Deku-Analyse v${VERSION}${NC}"
    echo -e "${CYAN}Telegram : ${WHITE}t.me/DarkDeku225${NC}"
    echo -e "${CYAN}GitHub : ${WHITE}github.com/Deku0019523f/Deku-Analyse${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}\n"
}

show_help() {
    cat << EOF
${CYAN}Deku-Analyse v${VERSION}${NC} - Outil de diagnostic et détection surveillance

${YELLOW}USAGE:${NC}
    ./deku-analyse.sh [OPTIONS]

${YELLOW}OPTIONS:${NC}
    -h, --help          Afficher cette aide
    -v, --version       Afficher la version
    -q, --quiet         Mode silencieux
    -r, --report        Générer un rapport et quitter
    -m, --monitor TIME  Monitoring pendant TIME minutes
    -s, --surveillance  Scan surveillance et quitter

${YELLOW}EXEMPLES:${NC}
    ./deku-analyse.sh              Mode interactif
    ./deku-analyse.sh -q -r        Rapport silencieux
    ./deku-analyse.sh -s           Scan surveillance

${CYAN}Contact: t.me/DarkDeku225${NC}
EOF
}

# ════════════════════════════════════════════════════════════════
#  FONCTIONS D'ANALYSE SYSTÈME (gardées du script précédent)
# ════════════════════════════════════════════════════════════════

get_system_info() {
    info "Informations Système"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Inconnu")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Inconnu")
    DEVICE_MANUFACTURER=$(getprop ro.product.manufacturer 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Appareil:${NC} $DEVICE_MANUFACTURER $DEVICE_BRAND $DEVICE_MODEL"

    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Inconnu")
    SDK_VERSION=$(getprop ro.build.version.sdk 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Android:${NC} Version $ANDROID_VERSION (SDK $SDK_VERSION)"

    KERNEL=$(uname -r 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Kernel:${NC} $KERNEL"

    ARCH=$(uname -m 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Architecture:${NC} $ARCH"

    if [ -f "/proc/uptime" ]; then
        UPTIME_SECONDS=$(cat /proc/uptime | awk '{print int($1)}')
        UPTIME_DAYS=$((UPTIME_SECONDS / 86400))
        UPTIME_HOURS=$(((UPTIME_SECONDS % 86400) / 3600))
        UPTIME_MINS=$(((UPTIME_SECONDS % 3600) / 60))
        echo -e "${GREEN}Uptime:${NC} ${UPTIME_DAYS}j ${UPTIME_HOURS}h ${UPTIME_MINS}m"
    fi

    echo ""
}

get_battery_info() {
    info "État de la Batterie"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if command -v termux-battery-status >/dev/null 2>&1; then
        BATTERY_JSON=$(termux-battery-status 2>/dev/null)
        if [ $? -eq 0 ]; then
            BATTERY_LEVEL=$(echo "$BATTERY_JSON" | grep -o '"percentage":[0-9]*' | cut -d: -f2)
            BATTERY_STATUS=$(echo "$BATTERY_JSON" | grep -o '"status":"[^"]*"' | cut -d: -f2 | tr -d '"')
            BATTERY_HEALTH=$(echo "$BATTERY_JSON" | grep -o '"health":"[^"]*"' | cut -d: -f2 | tr -d '"')
            BATTERY_TEMP=$(echo "$BATTERY_JSON" | grep -o '"temperature":[0-9.]*' | cut -d: -f2)

            echo -e "${GREEN}Niveau:${NC} ${BATTERY_LEVEL}%"
            echo -e "${GREEN}Statut:${NC} $BATTERY_STATUS"
            echo -e "${GREEN}Santé:${NC} $BATTERY_HEALTH"
            [ ! -z "$BATTERY_TEMP" ] && echo -e "${GREEN}Température:${NC} ${BATTERY_TEMP}°C"
        fi
    else
        if [ -f "/sys/class/power_supply/battery/capacity" ]; then
            BATTERY_LEVEL=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "N/A")
            echo -e "${GREEN}Niveau:${NC} ${BATTERY_LEVEL}%"
        fi

        if [ -f "/sys/class/power_supply/battery/status" ]; then
            BATTERY_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null || echo "N/A")
            echo -e "${GREEN}Statut:${NC} $BATTERY_STATUS"
        fi

        if [ -f "/sys/class/power_supply/battery/health" ]; then
            BATTERY_HEALTH=$(cat /sys/class/power_supply/battery/health 2>/dev/null || echo "N/A")
            echo -e "${GREEN}Santé:${NC} $BATTERY_HEALTH"
        fi
    fi

    echo ""
}

get_cpu_temp() {
    info "Température CPU"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    TEMP_FOUND=0
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            TEMP=$(cat "$zone" 2>/dev/null)
            if [ ! -z "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
                TEMP_C=$((TEMP / 1000))
                ZONE_TYPE=$(cat "$(dirname "$zone")/type" 2>/dev/null || echo "Unknown")

                if [ $TEMP_C -gt 70 ]; then
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${RED}${TEMP_C}°C (Élevée!)${NC}"
                elif [ $TEMP_C -gt 50 ]; then
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${YELLOW}${TEMP_C}°C (Modérée)${NC}"
                else
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${GREEN}${TEMP_C}°C (Normale)${NC}"
                fi
                TEMP_FOUND=1
            fi
        fi
    done

    [ $TEMP_FOUND -eq 0 ] && warn "Aucune zone thermique accessible"
    echo ""
}

get_ram_info() {
    info "Mémoire RAM"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_RAM=$((TOTAL_RAM - FREE_RAM))

        TOTAL_RAM_MB=$((TOTAL_RAM / 1024))
        FREE_RAM_MB=$((FREE_RAM / 1024))
        USED_RAM_MB=$((USED_RAM / 1024))
        USED_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))

        echo -e "${GREEN}Total:${NC} ${TOTAL_RAM_MB} MB"
        echo -e "${GREEN}Utilisée:${NC} ${USED_RAM_MB} MB (${USED_PERCENT}%)"
        echo -e "${GREEN}Disponible:${NC} ${FREE_RAM_MB} MB"
    fi
    echo ""
}

get_storage_info() {
    info "Stockage"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if df -h /sdcard >/dev/null 2>&1; then
        echo -e "${CYAN}Stockage Interne:${NC}"
        df -h /sdcard 2>/dev/null | tail -n 1 | awk '{
            printf "  \033[0;32mTotal:\033[0m %s\n", $2
            printf "  \033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
            printf "  \033[0;32mDisponible:\033[0m %s\n", $4
        }'
    fi
    echo ""
}

test_network_basic() {
    if [ -z "$PING_RESULT" ]; then
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            PING_RESULT="success"
            PING_TIME=$(ping -c 1 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
        else
            PING_RESULT="fail"
            PING_TIME=""
        fi
    fi
}

get_network_info() {
    info "Réseau"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    test_network_basic
    echo -ne "${GREEN}Test Ping (8.8.8.8):${NC} "
    if [ "$PING_RESULT" = "success" ]; then
        echo -e "${GREEN}✓ Connecté${NC} (${PING_TIME})"
    else
        echo -e "${RED}✗ Échec${NC}"
    fi

    if command -v ip >/dev/null 2>&1; then
        LOCAL_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        [ ! -z "$LOCAL_IP" ] && echo -e "${GREEN}IP Locale:${NC} $LOCAL_IP"
    fi
    echo ""
}

get_security_info() {
    info "Sécurité"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    echo -ne "${GREEN}Root:${NC} "
    if [ -f "/system/xbin/su" ] || [ -f "/system/bin/su" ] || command -v su >/dev/null 2>&1; then
        echo -e "${RED}Détecté${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    echo -ne "${GREEN}SELinux:${NC} "
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX=$(getenforce 2>/dev/null || echo "Unknown")
        echo -e "${CYAN}$SELINUX${NC}"
    else
        echo -e "${YELLOW}Non disponible${NC}"
    fi

    echo ""
}

generate_recommendation() {
    info "Recommandations"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    local has_issues=0

    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        if [ ! -z "$BATTERY" ] && [ "$BATTERY" -lt 20 ]; then
            warn "Batterie faible ($BATTERY%)"
            has_issues=1
        fi
    fi

    test_network_basic
    if [ "$PING_RESULT" != "success" ]; then
        warn "Pas de connexion Internet"
        has_issues=1
    fi

    if [ $has_issues -eq 0 ]; then
        success "Système en bon état"
    fi
    echo ""
}

# ════════════════════════════════════════════════════════════════
#  FONCTION DÉTECTION SURVEILLANCE / ÉCOUTE / PIRATAGE
# ════════════════════════════════════════════════════════════════

detect_surveillance() {
    show_banner
    echo -e "${RED}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}    DÉTECTION SURVEILLANCE / ÉCOUTE / PIRATAGE${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════${NC}\n"

    local threat_score=0
    local threats=()

    # 1. DÉTECTION APPLICATIONS ESPION
    info "🔍 Recherche d'Applications Espion"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    SPYWARE_PACKAGES=(
        "com.mspy" "com.spyzie" "com.flexispy" "com.hoverwatch"
        "com.spyera" "com.mobile-spy" "com.highster" "com.retina-x"
        "com.phonesheriff" "com.ikeymonitor" "com.spybubble" "com.copy9"
        "com.spyic" "com.cocospy" "com.spyine" "android.system.update"
        "android.process.media" "com.android.system.service"
    )

    SPYWARE_FOUND=()
    for package in "${SPYWARE_PACKAGES[@]}"; do
        if pm list packages 2>/dev/null | grep -q "$package"; then
            SPYWARE_FOUND+=("$package")
            threat_score=$((threat_score + 10))
        fi
    done

    if [ ${#SPYWARE_FOUND[@]} -gt 0 ]; then
        error "⚠️  SPYWARE DÉTECTÉ: ${#SPYWARE_FOUND[@]} app(s)"
        for spy in "${SPYWARE_FOUND[@]}"; do
            echo -e "  ${RED}→ $spy${NC}"
        done
        threats+=("Spyware installé")
    else
        success "Aucun spyware connu détecté"
    fi
    echo ""

    # 2. VÉRIFICATION RENVOI D'APPEL
    info "📞 Vérification Renvoi d'Appel / Écoute"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    echo -e "${CYAN}⚠️  Codes à tester manuellement sur le clavier:${NC}"
    echo -e "  ${YELLOW}*#21#${NC}  → Vérifier le renvoi d'appel"
    echo -e "  ${YELLOW}*#62#${NC}  → Vérifier renvoi si injoignable"
    echo -e "  ${YELLOW}*#67#${NC}  → Vérifier renvoi si occupé"
    echo -e "  ${RED}##002#${NC} → DÉSACTIVER tous les renvois"
    echo -e "  ${YELLOW}*#06#${NC}  → Afficher votre IMEI"
    echo ""

    # 3. APPLICATIONS CACHÉES
    info "👻 Recherche d'Applications Cachées"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    HIDDEN_COUNT=$(pm list packages 2>/dev/null | wc -l)
    echo -e "${GREEN}Applications installées:${NC} $HIDDEN_COUNT"

    # Apps système suspectes
    SUSPICIOUS_SYSTEM=$(pm list packages -s 2>/dev/null | grep -E "(update|media|service)" | grep -v "com.google" | grep -v "com.android.vending" | head -5)
    if [ ! -z "$SUSPICIOUS_SYSTEM" ]; then
        warn "Apps système à vérifier:"
        echo "$SUSPICIOUS_SYSTEM" | while read app; do
            echo -e "  ${YELLOW}→ $app${NC}"
        done
        threat_score=$((threat_score + 3))
    fi
    echo ""

    # 4. ADMINISTRATEURS DE PÉRIPHÉRIQUE
    info "🔒 Administrateurs de Périphérique"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if dumpsys device_policy >/dev/null 2>&1; then
        ADMINS=$(dumpsys device_policy 2>/dev/null | grep -i "admin" | grep -v "^$" | head -5)
        if [ ! -z "$ADMINS" ]; then
            warn "Administrateurs détectés (vérifiez leur légitimité):"
            echo "$ADMINS" | head -3
            threat_score=$((threat_score + 2))
        else
            success "Aucun administrateur suspect"
        fi
    fi
    echo ""

    # 5. CONNEXIONS RÉSEAU SUSPECTES
    info "🌐 Analyse des Connexions Réseau"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if command -v netstat >/dev/null 2>&1; then
        ESTABLISHED=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
        echo -e "${GREEN}Connexions établies:${NC} $ESTABLISHED"

        SUSPICIOUS_PORTS=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -E ":(27042|8888|9999|4444|5555)")
        if [ ! -z "$SUSPICIOUS_PORTS" ]; then
            error "⚠️  Ports suspects en écoute:"
            echo "$SUSPICIOUS_PORTS"
            threat_score=$((threat_score + 8))
            threats+=("Ports réseau suspects")
        else
            success "Aucun port suspect"
        fi
    else
        echo -e "${GRAY}netstat non disponible${NC}"
    fi
    echo ""

    # 6. PERMISSIONS DANGEREUSES
    info "🔐 Analyse des Permissions Dangereuses"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    echo -e "${CYAN}Apps avec accès MICROPHONE:${NC}"
    MIC_COUNT=$(dumpsys package 2>/dev/null | grep -c "android.permission.RECORD_AUDIO.*granted=true" || echo "?")
    echo -e "  ${YELLOW}$MIC_COUNT app(s) détectée(s)${NC}"

    echo -e "${CYAN}Apps avec accès LOCALISATION:${NC}"
    LOC_COUNT=$(dumpsys package 2>/dev/null | grep -c "android.permission.ACCESS_FINE_LOCATION.*granted=true" || echo "?")
    echo -e "  ${YELLOW}$LOC_COUNT app(s) détectée(s)${NC}"

    echo -e "${CYAN}Apps avec accès SMS:${NC}"
    SMS_COUNT=$(dumpsys package 2>/dev/null | grep -c "android.permission.READ_SMS.*granted=true" || echo "?")
    echo -e "  ${YELLOW}$SMS_COUNT app(s) détectée(s)${NC}"
    [ "$SMS_COUNT" != "?" ] && [ $SMS_COUNT -gt 3 ] && threat_score=$((threat_score + 2))
    echo ""

    # 7. COMPORTEMENT ANORMAL
    info "⚡ Analyse Comportement Système"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # Température
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            TEMP=$(cat "$zone" 2>/dev/null)
            if [ ! -z "$TEMP" ]; then
                TEMP_C=$((TEMP / 1000))
                if [ $TEMP_C -gt 50 ]; then
                    warn "Température élevée: ${TEMP_C}°C"
                    threat_score=$((threat_score + 1))
                else
                    success "Température normale: ${TEMP_C}°C"
                fi
                break
            fi
        fi
    done

    # RAM
    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_PERCENT=$(((TOTAL_RAM - FREE_RAM) * 100 / TOTAL_RAM))

        if [ $USED_PERCENT -gt 85 ]; then
            warn "RAM saturée: ${USED_PERCENT}%"
            threat_score=$((threat_score + 1))
        else
            success "RAM normale: ${USED_PERCENT}%"
        fi
    fi

    # Batterie
    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        if [ ! -z "$BATTERY" ]; then
            echo -e "${GREEN}Batterie:${NC} ${BATTERY}%"
        fi
    fi
    echo ""

    # 8. ROOTKITS ET MALWARES
    info "🦠 Scan Rootkits et Malwares"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    SUSPICIOUS_FILES=(
        "/system/xbin/su"
        "/system/bin/su"
        "/sbin/su"
        "/system/app/Superuser.apk"
        "/system/framework/XposedBridge.jar"
    )

    FOUND_COUNT=0
    for file in "${SUSPICIOUS_FILES[@]}"; do
        if [ -f "$file" ]; then
            warn "Fichier suspect: $file"
            FOUND_COUNT=$((FOUND_COUNT + 1))
            threat_score=$((threat_score + 3))
        fi
    done

    if [ $FOUND_COUNT -eq 0 ]; then
        success "Aucun fichier système suspect"
    else
        threats+=("Fichiers système modifiés")
    fi
    echo ""

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # SCORE FINAL
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              RÉSULTAT DE L'ANALYSE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    echo -ne "${WHITE}Score de Menace:${NC} "
    if [ $threat_score -eq 0 ]; then
        echo -e "${GREEN}$threat_score/100 - SÉCURISÉ ✓${NC}"
        echo -e "${GREEN}✓ Aucun signe de surveillance détecté${NC}"
    elif [ $threat_score -le 15 ]; then
        echo -e "${YELLOW}$threat_score/100 - RISQUE FAIBLE${NC}"
        echo -e "${YELLOW}Quelques points d'attention${NC}"
    elif [ $threat_score -le 40 ]; then
        echo -e "${YELLOW}$threat_score/100 - RISQUE MODÉRÉ ⚠${NC}"
        echo -e "${YELLOW}⚠  Surveillez les applications suspectes${NC}"
    else
        echo -e "${RED}$threat_score/100 - RISQUE ÉLEVÉ ⚠⚠⚠${NC}"
        echo -e "${RED}🚨 ATTENTION: Signes de surveillance détectés!${NC}"
    fi
    echo ""

    if [ ${#threats[@]} -gt 0 ]; then
        error "Menaces détectées:"
        for threat in "${threats[@]}"; do
            echo -e "  ${RED}✗${NC} $threat"
        done
        echo ""
    fi

    # RECOMMANDATIONS
    info "Recommandations"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if [ $threat_score -gt 20 ]; then
        echo -e "${RED}⚠️  ACTIONS URGENTES:${NC}"
        echo -e "  1. Testez ${YELLOW}*#21#${NC} pour vérifier le renvoi d'appel"
        echo -e "  2. Utilisez ${RED}##002#${NC} pour désactiver tous les renvois"
        echo -e "  3. Déinstallez les applications suspectes"
        echo -e "  4. Changez vos mots de passe importants"
        echo -e "  5. Activez l'authentification à 2 facteurs"
        echo -e "  6. Vérifiez Paramètres → Sécurité → Admin périphérique"
        echo -e "  7. Scannez avec Malwarebytes ou Kaspersky"
        echo -e "  8. Envisagez une réinitialisation d'usine"
    else
        echo -e "${GREEN}✓ BONNES PRATIQUES:${NC}"
        echo -e "  • Testez régulièrement ${YELLOW}*#21#${NC}"
        echo -e "  • Vérifiez les permissions des applications"
        echo -e "  • Installez uniquement depuis Play Store"
        echo -e "  • Gardez le système à jour"
        echo -e "  • Utilisez un antivirus de confiance"
    fi
    echo ""

    # SAUVEGARDE RAPPORT
    echo -ne "${YELLOW}Sauvegarder le rapport ? (o/n) : ${NC}"
    read -r SAVE_SURV

    if [ "$SAVE_SURV" = "o" ] || [ "$SAVE_SURV" = "O" ]; then
        SURV_REPORT="$REPORTS_DIR/surveillance_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "═══════════════════════════════════════════════════"
            echo "    RAPPORT DÉTECTION SURVEILLANCE/ÉCOUTE"
            echo "    Deku-Analyse v${VERSION}"
            echo "    Date: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "═══════════════════════════════════════════════════"
            echo ""
            echo "SCORE DE MENACE: $threat_score/100"
            echo ""
            echo "APPAREIL:"
            echo "  Modèle: $(getprop ro.product.model 2>/dev/null)"
            echo "  Android: $(getprop ro.build.version.release 2>/dev/null)"
            echo ""
            echo "MENACES DÉTECTÉES:"
            if [ ${#threats[@]} -eq 0 ]; then
                echo "  Aucune"
            else
                for threat in "${threats[@]}"; do
                    echo "  - $threat"
                done
            fi
            echo ""
            echo "SPYWARES TROUVÉS:"
            if [ ${#SPYWARE_FOUND[@]} -eq 0 ]; then
                echo "  Aucun"
            else
                for spy in "${SPYWARE_FOUND[@]}"; do
                    echo "  - $spy"
                done
            fi
            echo ""
            echo "CODES À TESTER:"
            echo "  *#21#  - Vérifier renvoi d'appel"
            echo "  ##002# - Désactiver tous les renvois"
            echo ""
            echo "═══════════════════════════════════════════════════"
            echo "Telegram: t.me/DarkDeku225"
            echo "═══════════════════════════════════════════════════"
        } > "$SURV_REPORT"
        success "Rapport sauvegardé: $SURV_REPORT"
    fi

    show_signature
}

# ════════════════════════════════════════════════════════════════
#  AUTRES FONCTIONS (versions simplifiées pour la démo)
# ════════════════════════════════════════════════════════════════

full_checkout() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         CHECKOUT COMPLET${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    get_system_info
    get_battery_info
    get_cpu_temp
    get_ram_info
    get_storage_info
    get_network_info
    get_security_info
    generate_recommendation

    show_signature
}

device_status() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           ÉTAT RAPIDE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        echo -e "${GREEN}🔋 Batterie:${NC} ${BATTERY}%"
    fi

    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            TEMP=$(cat "$zone" 2>/dev/null)
            if [ ! -z "$TEMP" ]; then
                TEMP_C=$((TEMP / 1000))
                echo -e "${GREEN}🌡️  Température:${NC} ${TEMP_C}°C"
                break
            fi
        fi
    done

    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null)
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null)
    echo -e "${GREEN}📱 Appareil:${NC} $DEVICE_MODEL"
    echo -e "${GREEN}🤖 Android:${NC} $ANDROID_VERSION"

    echo ""
    show_signature
}

# ════════════════════════════════════════════════════════════════
#  PROGRAMME PRINCIPAL
# ════════════════════════════════════════════════════════════════

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "Deku-Analyse v${VERSION}"
            exit 0
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -s|--surveillance)
            QUIET_MODE=false
            init_directories
            check_dependencies || exit 1
            detect_surveillance
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

init_directories
check_dependencies || exit 1

while true; do
    show_banner
    show_menu
    read -r OPTION

    case $OPTION in
        1)
            full_checkout
            read -p "Appuyez sur Entrée..." -r
            ;;
        2)
            device_status
            read -p "Appuyez sur Entrée..." -r
            ;;
        3)
            echo -e "${YELLOW}Fonction Monitoring - À implémenter${NC}"
            sleep 2
            ;;
        4)
            echo -e "${YELLOW}Fonction Sécurité Avancée - À implémenter${NC}"
            sleep 2
            ;;
        5)
            echo -e "${YELLOW}Fonction Réseau Détaillé - À implémenter${NC}"
            sleep 2
            ;;
        6)
            echo -e "${YELLOW}Fonction Historique - À implémenter${NC}"
            sleep 2
            ;;
        7)
            echo -e "${YELLOW}Fonction Configuration - À implémenter${NC}"
            sleep 2
            ;;
        8)
            detect_surveillance
            read -p "Appuyez sur Entrée..." -r
            ;;
        0)
            echo -e "${GREEN}Merci d'avoir utilisé Deku-Analyse !${NC}"
            exit 0
            ;;
        *)
            error "Option invalide"
            sleep 2
            ;;
    esac
done
