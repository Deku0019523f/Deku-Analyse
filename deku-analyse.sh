#!/data/data/com.termux/files/usr/bin/bash

# ════════════════════════════════════════════════════════════════
#  DEKU-ANALYSE v2.0 - Outil de diagnostic avancé pour Android
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
VERSION="2.0"
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

# Fonctions de logging colorées
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

# Créer les dossiers nécessaires
init_directories() {
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    mkdir -p "$LOGS_DIR" 2>/dev/null
}

# Vérifier les dépendances
check_dependencies() {
    local missing=()
    local optional_missing=()

    # Dépendances essentielles
    for cmd in ping df awk grep sed; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    # Dépendances optionnelles
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

# Afficher le banner
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

# Afficher le menu
show_menu() {
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[1]${NC} Checkout Complet"
    echo -e "${GREEN}[2]${NC} État Rapide de l'appareil"
    echo -e "${GREEN}[3]${NC} Mode Monitoring (Log continu)"
    echo -e "${GREEN}[4]${NC} Analyse de Sécurité Avancée"
    echo -e "${GREEN}[5]${NC} Test Réseau Détaillé"
    echo -e "${GREEN}[6]${NC} Historique des Rapports"
    echo -e "${GREEN}[7]${NC} Configuration"
    echo -e "${RED}[0]${NC} Quitter"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -ne "${YELLOW}CHOOSE AN OPTION : ${NC}"
}

# Afficher la signature
show_signature() {
    [ "$QUIET_MODE" = true ] && return
    echo -e "\n${WHITE}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Outil : ${WHITE}Deku-Analyse v${VERSION}${NC}"
    echo -e "${CYAN}Telegram : ${WHITE}t.me/DarkDeku225${NC}"
    echo -e "${CYAN}GitHub : ${WHITE}github.com/Deku0019523f/Deku-Analyse${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════${NC}\n"
}

# Afficher l'aide
show_help() {
    cat << EOF
${CYAN}Deku-Analyse v${VERSION}${NC} - Outil de diagnostic Android pour Termux

${YELLOW}USAGE:${NC}
    ./deku-analyse.sh [OPTIONS]

${YELLOW}OPTIONS:${NC}
    -h, --help          Afficher cette aide
    -v, --version       Afficher la version
    -q, --quiet         Mode silencieux (pas d'interface interactive)
    -r, --report        Générer un rapport complet et quitter
    -m, --monitor TIME  Lancer le monitoring pendant TIME minutes

${YELLOW}EXEMPLES:${NC}
    ./deku-analyse.sh              Lancer en mode interactif
    ./deku-analyse.sh -q -r        Générer un rapport en silence
    ./deku-analyse.sh -m 30        Monitorer pendant 30 minutes

${YELLOW}FICHIERS:${NC}
    reports/     Rapports générés
    logs/        Fichiers de monitoring

${CYAN}Contact: t.me/DarkDeku225${NC}
EOF
}

# ════════════════════════════════════════════════════════════════
#  FONCTIONS D'ANALYSE SYSTÈME
# ════════════════════════════════════════════════════════════════

# Obtenir les informations système
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

    # Uptime
    if [ -f "/proc/uptime" ]; then
        UPTIME_SECONDS=$(cat /proc/uptime | awk '{print int($1)}')
        UPTIME_DAYS=$((UPTIME_SECONDS / 86400))
        UPTIME_HOURS=$(((UPTIME_SECONDS % 86400) / 3600))
        UPTIME_MINS=$(((UPTIME_SECONDS % 3600) / 60))
        echo -e "${GREEN}Uptime:${NC} ${UPTIME_DAYS}j ${UPTIME_HOURS}h ${UPTIME_MINS}m"
    fi

    echo ""
}

# Obtenir les informations batterie
get_battery_info() {
    info "État de la Batterie"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # Utiliser termux-battery-status si disponible
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
        # Fallback sur /sys
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

        if [ -f "/sys/class/power_supply/battery/temp" ]; then
            BATTERY_TEMP=$(cat /sys/class/power_supply/battery/temp 2>/dev/null || echo "N/A")
            if [ "$BATTERY_TEMP" != "N/A" ]; then
                BATTERY_TEMP_C=$((BATTERY_TEMP / 10))
                echo -e "${GREEN}Température:${NC} ${BATTERY_TEMP_C}°C"
            fi
        fi
    fi

    # Informations supplémentaires
    if [ -f "/sys/class/power_supply/battery/voltage_now" ]; then
        VOLTAGE=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
        if [ ! -z "$VOLTAGE" ]; then
            VOLTAGE_V=$(awk "BEGIN {printf \"%.2f\", $VOLTAGE/1000000}")
            echo -e "${GREEN}Voltage:${NC} ${VOLTAGE_V}V"
        fi
    fi

    if [ -f "/sys/class/power_supply/battery/current_now" ]; then
        CURRENT=$(cat /sys/class/power_supply/battery/current_now 2>/dev/null)
        if [ ! -z "$CURRENT" ] && [ "$CURRENT" != "0" ]; then
            CURRENT_MA=$(awk "BEGIN {printf \"%.0f\", $CURRENT/1000}")
            echo -e "${GREEN}Courant:${NC} ${CURRENT_MA}mA"
        fi
    fi

    echo ""
}

# Obtenir la température CPU
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

                # Colorisation selon température
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

    [ $TEMP_FOUND -eq 0 ] && warn "Aucune zone thermique accessible sur ce modèle"
    echo ""
}

# Obtenir les informations RAM
get_ram_info() {
    info "Mémoire RAM"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        BUFFERS=$(grep Buffers /proc/meminfo | awk '{print $2}')
        CACHED=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
        USED_RAM=$((TOTAL_RAM - FREE_RAM))

        TOTAL_RAM_MB=$((TOTAL_RAM / 1024))
        FREE_RAM_MB=$((FREE_RAM / 1024))
        USED_RAM_MB=$((USED_RAM / 1024))
        BUFFERS_MB=$((BUFFERS / 1024))
        CACHED_MB=$((CACHED / 1024))

        USED_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))

        echo -e "${GREEN}Total:${NC} ${TOTAL_RAM_MB} MB"
        echo -e "${GREEN}Utilisée:${NC} ${USED_RAM_MB} MB (${USED_PERCENT}%)"
        echo -e "${GREEN}Disponible:${NC} ${FREE_RAM_MB} MB"
        echo -e "${GREEN}Buffers:${NC} ${BUFFERS_MB} MB"
        echo -e "${GREEN}Cache:${NC} ${CACHED_MB} MB"

        # Swap info
        SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        if [ "$SWAP_TOTAL" -gt 0 ]; then
            SWAP_FREE=$(grep SwapFree /proc/meminfo | awk '{print $2}')
            SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
            SWAP_TOTAL_MB=$((SWAP_TOTAL / 1024))
            SWAP_USED_MB=$((SWAP_USED / 1024))
            echo -e "${GREEN}Swap:${NC} ${SWAP_USED_MB}/${SWAP_TOTAL_MB} MB"
        fi
    else
        error "Impossible d'accéder à /proc/meminfo"
    fi
    echo ""
}

# Obtenir les informations stockage
get_storage_info() {
    info "Stockage"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # Stockage interne
    if df -h /sdcard >/dev/null 2>&1; then
        echo -e "${CYAN}Stockage Interne (/sdcard):${NC}"
        df -h /sdcard 2>/dev/null | tail -n 1 | awk '{
            printf "  \033[0;32mTotal:\033[0m %s\n", $2
            printf "  \033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
            printf "  \033[0;32mDisponible:\033[0m %s\n", $4
        }'
    fi

    # Stockage Termux
    echo -e "${CYAN}Stockage Termux:${NC}"
    df -h "$HOME" 2>/dev/null | tail -n 1 | awk '{
        printf "  \033[0;32mTotal:\033[0m %s\n", $2
        printf "  \033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
        printf "  \033[0;32mDisponible:\033[0m %s\n", $4
    }'

    echo ""
}

# Test réseau basique (cache le résultat)
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

# Obtenir les informations réseau
get_network_info() {
    info "Réseau"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # Test ping (utilise le cache)
    test_network_basic
    echo -ne "${GREEN}Test Ping (8.8.8.8):${NC} "
    if [ "$PING_RESULT" = "success" ]; then
        echo -e "${GREEN}✓ Connecté${NC} (${PING_TIME})"
    else
        echo -e "${RED}✗ Échec${NC}"
    fi

    # Test DNS
    echo -ne "${GREEN}Test DNS:${NC} "
    if command -v nslookup >/dev/null 2>&1; then
        if nslookup google.com >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Fonctionnel${NC}"
        else
            echo -e "${RED}✗ Échec${NC}"
        fi
    else
        echo -e "${YELLOW}nslookup non disponible${NC}"
    fi

    # VPN/Proxy detection
    echo -ne "${GREEN}VPN/Proxy:${NC} "
    if command -v ip >/dev/null 2>&1; then
        if ip route show 2>/dev/null | grep -q tun; then
            echo -e "${YELLOW}Détecté (interface tun)${NC}"
        else
            echo -e "${GREEN}Non détecté${NC}"
        fi
    else
        echo -e "${GRAY}Vérification non disponible${NC}"
    fi

    # IP locale
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        [ ! -z "$LOCAL_IP" ] && echo -e "${GREEN}IP Locale (WiFi):${NC} $LOCAL_IP"

        # Gateway
        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        [ ! -z "$GATEWAY" ] && echo -e "${GREEN}Passerelle:${NC} $GATEWAY"
    fi

    echo ""
}

# Analyse réseau détaillée
get_network_detailed() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           TEST RÉSEAU DÉTAILLÉ${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    # Interfaces réseau
    info "Interfaces Réseau"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr 2>/dev/null | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
    else
        ifconfig 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}'
    fi
    echo ""

    # Tests de connectivité multiples
    info "Tests de Connectivité"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    for host in "8.8.8.8:Google DNS" "1.1.1.1:Cloudflare" "208.67.222.222:OpenDNS"; do
        IP=$(echo "$host" | cut -d: -f1)
        NAME=$(echo "$host" | cut -d: -f2)
        echo -ne "${GREEN}$NAME ($IP):${NC} "
        if ping -c 1 -W 2 "$IP" >/dev/null 2>&1; then
            TIME=$(ping -c 1 "$IP" 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
            echo -e "${GREEN}✓${NC} $TIME"
        else
            echo -e "${RED}✗ Timeout${NC}"
        fi
    done
    echo ""

    # Ports ouverts (si netstat disponible)
    if command -v netstat >/dev/null 2>&1; then
        info "Ports en Écoute"
        echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
        netstat -tuln 2>/dev/null | grep LISTEN | head -n 10
        echo ""
    fi

    # DNS actuel
    info "Serveurs DNS"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    if [ -f "/etc/resolv.conf" ]; then
        grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print "  " $2}'
    else
        echo -e "${YELLOW}  /etc/resolv.conf non accessible${NC}"
    fi
    echo ""

    show_signature
}

# Analyse de sécurité
get_security_info() {
    info "Sécurité"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    local risk_score=0

    # Root detection
    echo -ne "${GREEN}Root:${NC} "
    if [ -f "/system/xbin/su" ] || [ -f "/system/bin/su" ] || [ -f "/sbin/su" ] || command -v su >/dev/null 2>&1; then
        echo -e "${RED}Détecté${NC}"
        risk_score=$((risk_score + 3))
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # Bootloader
    echo -ne "${GREEN}Bootloader:${NC} "
    BOOTLOADER_STATUS=$(getprop ro.boot.verifiedbootstate 2>/dev/null || echo "unknown")
    if [ "$BOOTLOADER_STATUS" = "green" ]; then
        echo -e "${GREEN}Verrouillé${NC}"
    else
        echo -e "${YELLOW}$BOOTLOADER_STATUS${NC}"
        risk_score=$((risk_score + 2))
    fi

    # SELinux
    echo -ne "${GREEN}SELinux:${NC} "
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX=$(getenforce 2>/dev/null || echo "Unknown")
        if [ "$SELINUX" = "Enforcing" ]; then
            echo -e "${GREEN}$SELINUX${NC}"
        else
            echo -e "${YELLOW}$SELINUX${NC}"
            risk_score=$((risk_score + 1))
        fi
    else
        echo -e "${YELLOW}Non disponible${NC}"
    fi

    # ADB Debug
    echo -ne "${GREEN}ADB Debug:${NC} "
    ADB_STATUS=$(getprop ro.debuggable 2>/dev/null || echo "0")
    if [ "$ADB_STATUS" = "1" ]; then
        echo -e "${YELLOW}Activé${NC}"
        risk_score=$((risk_score + 1))
    else
        echo -e "${GREEN}Désactivé${NC}"
    fi

    # Frida detection
    echo -ne "${GREEN}Frida:${NC} "
    FRIDA_DETECTED=0
    if pgrep -f frida >/dev/null 2>&1; then
        FRIDA_DETECTED=1
    elif command -v netstat >/dev/null 2>&1 && netstat -tuln 2>/dev/null | grep -q 27042; then
        FRIDA_DETECTED=1
    fi

    if [ $FRIDA_DETECTED -eq 1 ]; then
        echo -e "${RED}Détecté${NC}"
        risk_score=$((risk_score + 2))
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # Xposed detection
    echo -ne "${GREEN}Xposed:${NC} "
    if [ -f "/system/framework/XposedBridge.jar" ] || [ -f "/system/xposed.prop" ]; then
        echo -e "${YELLOW}Détecté${NC}"
        risk_score=$((risk_score + 2))
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # Score de risque
    echo ""
    echo -ne "${GREEN}Score de Risque:${NC} "
    if [ $risk_score -eq 0 ]; then
        echo -e "${GREEN}$risk_score/11 (Faible)${NC}"
    elif [ $risk_score -le 4 ]; then
        echo -e "${YELLOW}$risk_score/11 (Modéré)${NC}"
    else
        echo -e "${RED}$risk_score/11 (Élevé)${NC}"
    fi

    echo ""
}

# Analyse de sécurité avancée
security_advanced_check() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}        ANALYSE DE SÉCURITÉ AVANCÉE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    get_security_info

    # Vérifications additionnelles
    info "Vérifications Additionnelles"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # Magisk
    echo -ne "${GREEN}Magisk:${NC} "
    if [ -d "/data/adb/magisk" ] || command -v magisk >/dev/null 2>&1; then
        echo -e "${YELLOW}Détecté${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # Developer Options
    echo -ne "${GREEN}Options Développeur:${NC} "
    DEV_SETTINGS=$(getprop persist.sys.usb.config 2>/dev/null)
    if echo "$DEV_SETTINGS" | grep -q "adb"; then
        echo -e "${YELLOW}Probablement activées${NC}"
    else
        echo -e "${GREEN}Probablement désactivées${NC}"
    fi

    # Encryption
    echo -ne "${GREEN}Chiffrement:${NC} "
    ENCRYPT_STATE=$(getprop ro.crypto.state 2>/dev/null)
    if [ "$ENCRYPT_STATE" = "encrypted" ]; then
        echo -e "${GREEN}Activé${NC}"
    else
        echo -e "${YELLOW}$ENCRYPT_STATE${NC}"
    fi

    # Knox (Samsung)
    echo -ne "${GREEN}Samsung Knox:${NC} "
    KNOX_STATE=$(getprop ro.boot.warranty_bit 2>/dev/null)
    if [ ! -z "$KNOX_STATE" ]; then
        if [ "$KNOX_STATE" = "0" ]; then
            echo -e "${GREEN}Intact${NC}"
        else
            echo -e "${RED}Compromis${NC}"
        fi
    else
        echo -e "${GRAY}Non applicable${NC}"
    fi

    echo ""

    # Recommandations de sécurité
    info "Recommandations de Sécurité"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    local recommendations=()

    [ "$ADB_STATUS" = "1" ] && recommendations+=("Désactivez le débogage USB quand non utilisé")
    [ "$SELINUX" != "Enforcing" ] && recommendations+=("Activez SELinux en mode Enforcing si possible")
    [ $FRIDA_DETECTED -eq 1 ] && recommendations+=("Frida détecté - vérifiez les apps suspectes")
    [ "$ENCRYPT_STATE" != "encrypted" ] && recommendations+=("Activez le chiffrement du stockage")

    if [ ${#recommendations[@]} -eq 0 ]; then
        success "Aucune recommandation - configuration sécurisée"
    else
        for rec in "${recommendations[@]}"; do
            echo -e "  ${YELLOW}•${NC} $rec"
        done
    fi

    echo ""
    show_signature
}

# Générer des recommandations
generate_recommendation() {
    info "Recommandations"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    local has_issues=0

    # Vérifier la batterie
    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        if [ ! -z "$BATTERY" ] && [ "$BATTERY" -lt 20 ]; then
            warn "Batterie faible ($BATTERY%) - Rechargez votre appareil"
            has_issues=1
        fi
    fi

    # Vérifier la RAM
    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_PERCENT=$((($TOTAL_RAM - $FREE_RAM) * 100 / $TOTAL_RAM))

        if [ $USED_PERCENT -gt 85 ]; then
            warn "Utilisation RAM élevée (${USED_PERCENT}%) - Fermez des applications"
            has_issues=1
        fi
    fi

    # Vérifier le stockage
    STORAGE_USED=$(df /sdcard 2>/dev/null | tail -n 1 | awk '{print $5}' | tr -d '%')
    if [ ! -z "$STORAGE_USED" ] && [ "$STORAGE_USED" -gt 90 ]; then
        warn "Stockage presque plein (${STORAGE_USED}%) - Libérez de l'espace"
        has_issues=1
    fi

    # Vérifier la connectivité
    test_network_basic
    if [ "$PING_RESULT" != "success" ]; then
        warn "Pas de connexion Internet détectée"
        has_issues=1
    fi

    # Température
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            TEMP=$(cat "$zone" 2>/dev/null)
            if [ ! -z "$TEMP" ]; then
                TEMP_C=$((TEMP / 1000))
                if [ $TEMP_C -gt 70 ]; then
                    warn "Température CPU élevée (${TEMP_C}°C) - Laissez refroidir"
                    has_issues=1
                    break
                fi
            fi
        fi
    done

    if [ $has_issues -eq 0 ]; then
        success "Aucun problème détecté - Système en bon état"
    fi

    echo ""
}

# ════════════════════════════════════════════════════════════════
#  FONCTIONS PRINCIPALES
# ════════════════════════════════════════════════════════════════

# Option 1: Checkout Complet
full_checkout() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         CHECKOUT COMPLET DE L'APPAREIL${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    get_system_info
    get_battery_info
    get_cpu_temp
    get_ram_info
    get_storage_info
    get_network_info
    get_security_info
    generate_recommendation

    # Demander si l'utilisateur veut sauvegarder
    if [ "$QUIET_MODE" = false ]; then
        echo -ne "${YELLOW}Sauvegarder le rapport ? (o/n/j pour JSON) : ${NC}"
        read -r SAVE_REPORT
    else
        SAVE_REPORT="o"
    fi

    if [ "$SAVE_REPORT" = "o" ] || [ "$SAVE_REPORT" = "O" ] || [ "$SAVE_REPORT" = "j" ] || [ "$SAVE_REPORT" = "J" ]; then
        REPORT_FILE="$REPORTS_DIR/rapport_$(date +%Y%m%d_%H%M%S)"

        if [ "$SAVE_REPORT" = "j" ] || [ "$SAVE_REPORT" = "J" ]; then
            REPORT_FILE="${REPORT_FILE}.json"
            save_report_json "$REPORT_FILE"
        else
            REPORT_FILE="${REPORT_FILE}.txt"
            save_report_text "$REPORT_FILE"
        fi

        success "Rapport sauvegardé : $REPORT_FILE"
    fi

    show_signature
}

# Option 2: État rapide
device_status() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           ÉTAT RAPIDE DE L'APPAREIL${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    # Batterie
    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        echo -e "${GREEN}🔋 Batterie:${NC} ${BATTERY}%"
    fi

    # Température
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

    # RAM
    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_RAM=$((TOTAL_RAM - FREE_RAM))
        USED_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))
        TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_RAM/1024/1024}")
        echo -e "${GREEN}💾 RAM:${NC} ${USED_PERCENT}% utilisée (${TOTAL_RAM_GB} GB total)"
    fi

    # Stockage
    STORAGE_INFO=$(df -h /sdcard 2>/dev/null | tail -n 1 | awk '{print $3 "/" $2 " (" $5 ")"}')
    echo -e "${GREEN}💿 Stockage:${NC} $STORAGE_INFO"

    # Ping
    echo -ne "${GREEN}🌐 Internet:${NC} "
    test_network_basic
    if [ "$PING_RESULT" = "success" ]; then
        echo -e "${GREEN}Connecté ✓${NC} (${PING_TIME})"
    else
        echo -e "${RED}Déconnecté ✗${NC}"
    fi

    # Modèle + Android
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null)
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null)
    echo -e "${GREEN}📱 Appareil:${NC} $DEVICE_MODEL"
    echo -e "${GREEN}🤖 Android:${NC} $ANDROID_VERSION"

    echo ""
    show_signature
}

# Option 3: Mode Monitoring
monitoring_mode() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}            MODE MONITORING CONTINU${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    info "Configuration du monitoring"
    echo -ne "${YELLOW}Intervalle entre les mesures (secondes) [60]: ${NC}"
    read -r INTERVAL
    INTERVAL=${INTERVAL:-60}

    echo -ne "${YELLOW}Durée totale (minutes) [0=infini]: ${NC}"
    read -r DURATION
    DURATION=${DURATION:-0}

    LOG_FILE="$LOGS_DIR/monitor_$(date +%Y%m%d_%H%M%S).log"

    info "Logging vers: $LOG_FILE"
    info "Appuyez sur Ctrl+C pour arrêter"
    echo ""

    # En-tête du fichier log
    echo "# Deku-Analyse Monitoring Log" > "$LOG_FILE"
    echo "# Démarré: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "# Intervalle: ${INTERVAL}s" >> "$LOG_FILE"
    echo "# Format: Timestamp,Battery%,Temp°C,RAM%,Storage%,Ping(ms)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    local count=0
    local max_count=$((DURATION * 60 / INTERVAL))

    while true; do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

        # Collecter les données
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "N/A")

        TEMP="N/A"
        for zone in /sys/class/thermal/thermal_zone*/temp; do
            if [ -f "$zone" ]; then
                TEMP=$(cat "$zone" 2>/dev/null)
                if [ ! -z "$TEMP" ]; then
                    TEMP=$((TEMP / 1000))
                    break
                fi
            fi
        done

        if [ -f "/proc/meminfo" ]; then
            TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
            RAM_PERCENT=$(((TOTAL_RAM - FREE_RAM) * 100 / TOTAL_RAM))
        else
            RAM_PERCENT="N/A"
        fi

        STORAGE_PERCENT=$(df /sdcard 2>/dev/null | tail -n 1 | awk '{print $5}' | tr -d '%')

        PING_MS="N/A"
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            PING_MS=$(ping -c 1 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | sed 's/ms//')
        fi

        # Écrire dans le log
        echo "$TIMESTAMP,$BATTERY,$TEMP,$RAM_PERCENT,$STORAGE_PERCENT,$PING_MS" >> "$LOG_FILE"

        # Afficher à l'écran
        echo -e "${CYAN}[$TIMESTAMP]${NC} Bat:${BATTERY}% Temp:${TEMP}°C RAM:${RAM_PERCENT}% Storage:${STORAGE_PERCENT}% Ping:${PING_MS}ms"

        count=$((count + 1))

        # Vérifier si on doit arrêter
        if [ $DURATION -gt 0 ] && [ $count -ge $max_count ]; then
            echo ""
            success "Monitoring terminé après $DURATION minute(s)"
            break
        fi

        sleep "$INTERVAL"
    done

    echo ""
    info "Log sauvegardé: $LOG_FILE"
    show_signature
}

# Option 6: Historique des rapports
show_reports_history() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}          HISTORIQUE DES RAPPORTS${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    if [ ! -d "$REPORTS_DIR" ] || [ -z "$(ls -A "$REPORTS_DIR" 2>/dev/null)" ]; then
        warn "Aucun rapport trouvé dans $REPORTS_DIR"
    else
        info "Rapports disponibles:"
        echo ""
        ls -lht "$REPORTS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}'
        echo ""

        echo -ne "${YELLOW}Ouvrir un rapport ? (nom du fichier ou 'n' pour annuler): ${NC}"
        read -r REPORT_NAME

        if [ "$REPORT_NAME" != "n" ] && [ "$REPORT_NAME" != "N" ] && [ ! -z "$REPORT_NAME" ]; then
            REPORT_PATH="$REPORTS_DIR/$REPORT_NAME"
            if [ -f "$REPORT_PATH" ]; then
                echo ""
                cat "$REPORT_PATH"
                echo ""
            else
                error "Rapport non trouvé: $REPORT_PATH"
            fi
        fi
    fi

    echo ""

    # Logs
    if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR" 2>/dev/null)" ]; then
        warn "Aucun log trouvé dans $LOGS_DIR"
    else
        info "Logs de monitoring disponibles:"
        echo ""
        ls -lht "$LOGS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}'
    fi

    echo ""
    show_signature
}

# Option 7: Configuration
show_configuration() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              CONFIGURATION${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    info "Paramètres actuels"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Version:${NC} $VERSION"
    echo -e "${GREEN}Dossier rapports:${NC} $REPORTS_DIR"
    echo -e "${GREEN}Dossier logs:${NC} $LOGS_DIR"
    echo -e "${GREEN}Mode silencieux:${NC} $QUIET_MODE"
    echo ""

    info "Dépendances"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    for cmd in ping df awk grep sed termux-battery-status nslookup ip netstat; do
        echo -ne "${GREEN}$cmd:${NC} "
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Installé${NC}"
        else
            echo -e "${RED}✗ Manquant${NC}"
        fi
    done
    echo ""

    info "Actions"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}[1]${NC} Nettoyer les anciens rapports (>30 jours)"
    echo -e "${GREEN}[2]${NC} Nettoyer les anciens logs (>30 jours)"
    echo -e "${GREEN}[3]${NC} Installer les dépendances manquantes"
    echo -e "${GREEN}[0]${NC} Retour"
    echo ""

    echo -ne "${YELLOW}Choisir une action : ${NC}"
    read -r CONFIG_OPTION

    case $CONFIG_OPTION in
        1)
            info "Nettoyage des rapports de plus de 30 jours..."
            find "$REPORTS_DIR" -type f -mtime +30 -delete 2>/dev/null
            success "Nettoyage terminé"
            ;;
        2)
            info "Nettoyage des logs de plus de 30 jours..."
            find "$LOGS_DIR" -type f -mtime +30 -delete 2>/dev/null
            success "Nettoyage terminé"
            ;;
        3)
            info "Installation des dépendances..."
            pkg update && pkg install -y termux-api iproute2 net-tools dnsutils
            success "Installation terminée"
            ;;
    esac

    echo ""
    show_signature
}

# Sauvegarder rapport texte
save_report_text() {
    local file="$1"
    {
        echo "═══════════════════════════════════════════════════"
        echo "         RAPPORT DEKU-ANALYSE v${VERSION}"
        echo "         Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════"
        echo ""
        echo "SYSTÈME:"
        echo "--------"
        echo "Appareil: $(getprop ro.product.manufacturer) $(getprop ro.product.brand) $(getprop ro.product.model)"
        echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo ""
        echo "BATTERIE:"
        echo "---------"
        [ -f "/sys/class/power_supply/battery/capacity" ] && echo "Niveau: $(cat /sys/class/power_supply/battery/capacity)%"
        [ -f "/sys/class/power_supply/battery/status" ] && echo "Statut: $(cat /sys/class/power_supply/battery/status)"
        [ -f "/sys/class/power_supply/battery/health" ] && echo "Santé: $(cat /sys/class/power_supply/battery/health)"
        echo ""
        echo "MÉMOIRE:"
        echo "--------"
        if [ -f "/proc/meminfo" ]; then
            TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
            echo "Total: $((TOTAL_RAM / 1024)) MB"
            echo "Disponible: $((FREE_RAM / 1024)) MB"
        fi
        echo ""
        echo "STOCKAGE:"
        echo "---------"
        df -h /sdcard 2>/dev/null | tail -n 1
        echo ""
        echo "RÉSEAU:"
        echo "-------"
        test_network_basic
        echo "Connectivité: $PING_RESULT"
        [ ! -z "$PING_TIME" ] && echo "Ping: $PING_TIME"
        echo ""
        echo "═══════════════════════════════════════════════════"
        echo "Outil : Deku-Analyse v${VERSION}"
        echo "Telegram : t.me/DarkDeku225"
        echo "═══════════════════════════════════════════════════"
    } > "$file"
}

# Sauvegarder rapport JSON
save_report_json() {
    local file="$1"
    {
        echo "{"
        echo "  \"version\": \"$VERSION\","
        echo "  \"timestamp\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
        echo "  \"device\": {"
        echo "    \"model\": \"$(getprop ro.product.model)\","
        echo "    \"brand\": \"$(getprop ro.product.brand)\","
        echo "    \"manufacturer\": \"$(getprop ro.product.manufacturer)\","
        echo "    \"android_version\": \"$(getprop ro.build.version.release)\","
        echo "    \"sdk\": $(getprop ro.build.version.sdk),"
        echo "    \"kernel\": \"$(uname -r)\","
        echo "    \"arch\": \"$(uname -m)\""
        echo "  },"

        if [ -f "/sys/class/power_supply/battery/capacity" ]; then
            echo "  \"battery\": {"
            echo "    \"level\": $(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo 0),"
            echo "    \"status\": \"$(cat /sys/class/power_supply/battery/status 2>/dev/null || echo "Unknown")\""
            echo "  },"
        fi

        if [ -f "/proc/meminfo" ]; then
            TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
            echo "  \"memory\": {"
            echo "    \"total_kb\": $TOTAL_RAM,"
            echo "    \"available_kb\": $FREE_RAM,"
            echo "    \"used_percent\": $(((TOTAL_RAM - FREE_RAM) * 100 / TOTAL_RAM))"
            echo "  },"
        fi

        test_network_basic
        echo "  \"network\": {"
        echo "    \"connected\": $([ "$PING_RESULT" = "success" ] && echo "true" || echo "false")"
        [ ! -z "$PING_TIME" ] && echo "    , \"ping_ms\": \"$PING_TIME\""
        echo "  }"

        echo "}"
    } > "$file"
}

# ════════════════════════════════════════════════════════════════
#  PROGRAMME PRINCIPAL
# ════════════════════════════════════════════════════════════════

# Parser les arguments
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
        -r|--report)
            QUIET_MODE=true
            init_directories
            check_dependencies || exit 1
            full_checkout
            exit 0
            ;;
        -m|--monitor)
            MONITOR_TIME="$2"
            shift 2
            # Lancer monitoring et quitter
            ;;
        *)
            echo "Option inconnue: $1"
            echo "Utilisez -h pour l'aide"
            exit 1
            ;;
    esac
done

# Initialisation
init_directories
check_dependencies || exit 1

# Boucle principale
while true; do
    show_banner
    show_menu
    read -r OPTION

    case $OPTION in
        1)
            full_checkout
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        2)
            device_status
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        3)
            monitoring_mode
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        4)
            security_advanced_check
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        5)
            get_network_detailed
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        6)
            show_reports_history
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        7)
            show_configuration
            [ "$QUIET_MODE" = false ] && read -p "Appuyez sur Entrée pour continuer..." -r
            ;;
        0)
            echo -e "${GREEN}Merci d'avoir utilisé Deku-Analyse !${NC}"
            exit 0
            ;;
        *)
            error "Option invalide. Veuillez réessayer."
            sleep 2
            ;;
    esac
done
