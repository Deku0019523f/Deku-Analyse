#!/data/data/com.termux/files/usr/bin/bash

# ════════════════════════════════════════════════════════════════
#  DEKU-ANALYSE v2.1 - Outil complet de diagnostic Android
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

# Seuils par défaut (surchargés par .deku-config si présent)
BATTERY_LOW_THRESHOLD=20
RAM_HIGH_THRESHOLD=85
STORAGE_HIGH_THRESHOLD=90
CPU_TEMP_WARN=50
CPU_TEMP_HIGH=70

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE" 2>/dev/null
    else
        save_config
    fi
}

save_config() {
    {
        echo "# Deku-Analyse - Configuration des seuils"
        echo "BATTERY_LOW_THRESHOLD=$BATTERY_LOW_THRESHOLD"
        echo "RAM_HIGH_THRESHOLD=$RAM_HIGH_THRESHOLD"
        echo "STORAGE_HIGH_THRESHOLD=$STORAGE_HIGH_THRESHOLD"
        echo "CPU_TEMP_WARN=$CPU_TEMP_WARN"
        echo "CPU_TEMP_HIGH=$CPU_TEMP_HIGH"
    } > "$CONFIG_FILE" 2>/dev/null
}

reset_network_cache() {
    PING_RESULT=""
    PING_TIME=""
}

get_battery_percentage() {
    local level=""
    if command -v termux-battery-status >/dev/null 2>&1; then
        local json
        json=$(timeout 5 termux-battery-status 2>/dev/null)
        level=$(echo "$json" | grep -o '"percentage"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
    fi
    if ! [[ "$level" =~ ^[0-9]+$ ]]; then
        level=""
        for f in /sys/class/power_supply/battery/capacity /sys/class/power_supply/bat0/capacity /sys/class/power_supply/BAT0/capacity; do
            if [ -f "$f" ]; then
                local val
                val=$(cat "$f" 2>/dev/null)
                if [[ "$val" =~ ^[0-9]+$ ]]; then
                    level="$val"
                    break
                fi
            fi
        done
    fi
    echo "$level"
}

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
|____/ \___|_|\_\\__,_|

    _                _                 
   / \   _ __   __ _| |_   _ ___  ___ 
  / _ \ | '_ \ / _` | | | | / __|/ _ \
 / ___ \| | | | (_| | | |_| \__ \  __/
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
${CYAN}Deku-Analyse v${VERSION}${NC} - Outil de diagnostic Android complet

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
    ./deku-analyse.sh -m 30        Monitoring 30 min

${CYAN}Contact: t.me/DarkDeku225${NC}
EOF
}

# ════════════════════════════════════════════════════════════════
#  FONCTIONS D'ANALYSE SYSTÈME
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

    BATTERY_LEVEL=""
    BATTERY_STATUS=""
    BATTERY_HEALTH=""
    BATTERY_TEMP=""

    if command -v termux-battery-status >/dev/null 2>&1; then
        BATTERY_JSON=$(timeout 5 termux-battery-status 2>/dev/null)
        BATTERY_LEVEL=$(echo "$BATTERY_JSON" | grep -o '"percentage"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
        BATTERY_STATUS=$(echo "$BATTERY_JSON" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        BATTERY_HEALTH=$(echo "$BATTERY_JSON" | grep -o '"health"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        BATTERY_TEMP=$(echo "$BATTERY_JSON" | grep -o '"temperature"[[:space:]]*:[[:space:]]*[0-9.]*' | grep -o '[0-9.]*$')
    fi

    # Si termux-battery-status n'est pas installé OU répond sans le champ
    # "percentage" (app Termux:API absente/permission refusée : cas fréquent),
    # on retombe sur la lecture directe du système de fichiers.
    if ! [[ "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
        BATTERY_LEVEL=""
        for f in /sys/class/power_supply/battery/capacity /sys/class/power_supply/bat0/capacity /sys/class/power_supply/BAT0/capacity; do
            if [ -f "$f" ]; then
                VAL=$(cat "$f" 2>/dev/null)
                if [[ "$VAL" =~ ^[0-9]+$ ]]; then
                    BATTERY_LEVEL="$VAL"
                    break
                fi
            fi
        done
        [ -z "$BATTERY_STATUS" ] && [ -f "/sys/class/power_supply/battery/status" ] && BATTERY_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
        [ -z "$BATTERY_HEALTH" ] && [ -f "/sys/class/power_supply/battery/health" ] && BATTERY_HEALTH=$(cat /sys/class/power_supply/battery/health 2>/dev/null)
        if [ -z "$BATTERY_TEMP" ] && [ -f "/sys/class/power_supply/battery/temp" ]; then
            RAW_TEMP=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
            [[ "$RAW_TEMP" =~ ^[0-9]+$ ]] && BATTERY_TEMP=$(awk "BEGIN {printf \"%.1f\", $RAW_TEMP/10}")
        fi
    fi

    if [ -n "$BATTERY_LEVEL" ]; then
        echo -e "${GREEN}Niveau:${NC} ${BATTERY_LEVEL}%"
        [ -n "$BATTERY_STATUS" ] && echo -e "${GREEN}Statut:${NC} $BATTERY_STATUS"
        [ -n "$BATTERY_HEALTH" ] && echo -e "${GREEN}Santé:${NC} $BATTERY_HEALTH"
        [ -n "$BATTERY_TEMP" ] && echo -e "${GREEN}Température:${NC} ${BATTERY_TEMP}°C"
    else
        warn "Information batterie indisponible"
        echo -e "${GRAY}  → Installez l'app Termux:API (F-Droid/Play Store) en plus du paquet 'termux-api',${NC}"
        echo -e "${GRAY}    ou accordez-lui la permission si elle est déjà installée.${NC}"
    fi

    if [ -f "/sys/class/power_supply/battery/voltage_now" ]; then
        VOLTAGE=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
        if [ ! -z "$VOLTAGE" ] && [ "$VOLTAGE" != "0" ]; then
            VOLTAGE_V=$(awk "BEGIN {printf \"%.2f\", $VOLTAGE/1000000}")
            echo -e "${GREEN}Voltage:${NC} ${VOLTAGE_V}V"
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

                if [ "$TEMP_C" -gt "$CPU_TEMP_HIGH" ]; then
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${RED}${TEMP_C}°C (Élevée!)${NC}"
                elif [ "$TEMP_C" -gt "$CPU_TEMP_WARN" ]; then
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${YELLOW}${TEMP_C}°C (Modérée)${NC}"
                else
                    echo -e "${GREEN}$ZONE_TYPE:${NC} ${GREEN}${TEMP_C}°C (Normale)${NC}"
                fi
                TEMP_FOUND=1
            fi
        fi
    done

    if [ $TEMP_FOUND -eq 0 ]; then
        warn "Aucune zone thermique accessible"
        echo -e "${GRAY}  → Souvent bloqué par SELinux/Knox sur certains Samsung sans root${NC}"
    fi
    echo ""
}

get_ram_info() {
    info "Mémoire RAM"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        BUFFERS=$(grep Buffers /proc/meminfo | awk '{print $2}')
        CACHED=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')

        if ! [[ "$TOTAL_RAM" =~ ^[0-9]+$ ]] || [ "$TOTAL_RAM" -eq 0 ]; then
            warn "Impossible de lire les informations RAM (/proc/meminfo incomplet)"
            echo ""
            return
        fi
        [[ "$FREE_RAM" =~ ^[0-9]+$ ]] || FREE_RAM=0
        [[ "$BUFFERS" =~ ^[0-9]+$ ]] || BUFFERS=0
        [[ "$CACHED" =~ ^[0-9]+$ ]] || CACHED=0

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

        SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        if [ "$SWAP_TOTAL" -gt 0 ]; then
            SWAP_FREE=$(grep SwapFree /proc/meminfo | awk '{print $2}')
            SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
            SWAP_TOTAL_MB=$((SWAP_TOTAL / 1024))
            SWAP_USED_MB=$((SWAP_USED / 1024))
            echo -e "${GREEN}Swap:${NC} ${SWAP_USED_MB}/${SWAP_TOTAL_MB} MB"
        fi
    fi
    echo ""
}

get_storage_info() {
    info "Stockage"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if df -h /sdcard >/dev/null 2>&1; then
        echo -e "${CYAN}Stockage Interne (/sdcard):${NC}"
        df -h /sdcard 2>/dev/null | tail -n 1 | awk '{
            printf "  \033[0;32mTotal:\033[0m %s\n", $2
            printf "  \033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
            printf "  \033[0;32mDisponible:\033[0m %s\n", $4
        }'
    fi

    echo -e "${CYAN}Stockage Termux:${NC}"
    df -h "$HOME" 2>/dev/null | tail -n 1 | awk '{
        printf "  \033[0;32mTotal:\033[0m %s\n", $2
        printf "  \033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
        printf "  \033[0;32mDisponible:\033[0m %s\n", $4
    }'

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

    reset_network_cache
    test_network_basic
    echo -ne "${GREEN}Test Ping (8.8.8.8):${NC} "
    if [ "$PING_RESULT" = "success" ]; then
        echo -e "${GREEN}✓ Connecté${NC} (${PING_TIME})"
    else
        echo -e "${RED}✗ Échec${NC}"
    fi

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

    echo -ne "${GREEN}VPN/Proxy:${NC} "
    if command -v ip >/dev/null 2>&1; then
        if ip route show 2>/dev/null | grep -q tun; then
            echo -e "${YELLOW}Détecté (interface tun)${NC}"
        else
            echo -e "${GREEN}Non détecté${NC}"
        fi
    else
        echo -e "${GRAY}Non vérifiable${NC}"
    fi

    if command -v ip >/dev/null 2>&1; then
        LOCAL_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        [ ! -z "$LOCAL_IP" ] && echo -e "${GREEN}IP Locale (WiFi):${NC} $LOCAL_IP"

        GATEWAY=$(ip route 2>/dev/null | grep default | awk '{print $3}')
        [ ! -z "$GATEWAY" ] && echo -e "${GREEN}Passerelle:${NC} $GATEWAY"
    fi

    echo ""
}

get_security_info() {
    info "Sécurité"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    risk_score=0

    echo -ne "${GREEN}Root:${NC} "
    if [ -f "/system/xbin/su" ] || [ -f "/system/bin/su" ] || [ -f "/sbin/su" ] || command -v su >/dev/null 2>&1; then
        echo -e "${RED}Détecté${NC}"
        risk_score=$((risk_score + 3))
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    echo -ne "${GREEN}Bootloader:${NC} "
    BOOTLOADER_STATUS=$(getprop ro.boot.verifiedbootstate 2>/dev/null || echo "unknown")
    if [ "$BOOTLOADER_STATUS" = "green" ]; then
        echo -e "${GREEN}Verrouillé${NC}"
    else
        echo -e "${YELLOW}$BOOTLOADER_STATUS${NC}"
        risk_score=$((risk_score + 2))
    fi

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

    echo -ne "${GREEN}ADB Debug:${NC} "
    ADB_STATUS=$(getprop ro.debuggable 2>/dev/null || echo "0")
    if [ "$ADB_STATUS" = "1" ]; then
        echo -e "${YELLOW}Activé${NC}"
        risk_score=$((risk_score + 1))
    else
        echo -e "${GREEN}Désactivé${NC}"
    fi

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

    echo -ne "${GREEN}Xposed:${NC} "
    if [ -f "/system/framework/XposedBridge.jar" ] || [ -f "/system/xposed.prop" ]; then
        echo -e "${YELLOW}Détecté${NC}"
        risk_score=$((risk_score + 2))
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

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

generate_recommendation() {
    info "Recommandations"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    local has_issues=0

    BATTERY=$(get_battery_percentage)
    if [[ "$BATTERY" =~ ^[0-9]+$ ]] && [ "$BATTERY" -lt "$BATTERY_LOW_THRESHOLD" ]; then
        warn "Batterie faible ($BATTERY%) - Rechargez"
        has_issues=1
    fi

    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [[ "$TOTAL_RAM" =~ ^[0-9]+$ ]] && [ "$TOTAL_RAM" -gt 0 ]; then
            [[ "$FREE_RAM" =~ ^[0-9]+$ ]] || FREE_RAM=0
            USED_PERCENT=$((($TOTAL_RAM - $FREE_RAM) * 100 / $TOTAL_RAM))
            if [ "$USED_PERCENT" -gt "$RAM_HIGH_THRESHOLD" ]; then
                warn "RAM élevée (${USED_PERCENT}%) - Fermez des apps"
                has_issues=1
            fi
        fi
    fi

    STORAGE_USED=$(df /sdcard 2>/dev/null | tail -n 1 | awk '{print $5}' | tr -d '%')
    if [[ "$STORAGE_USED" =~ ^[0-9]+$ ]] && [ "$STORAGE_USED" -gt "$STORAGE_HIGH_THRESHOLD" ]; then
        warn "Stockage plein (${STORAGE_USED}%) - Libérez de l'espace"
        has_issues=1
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
#  DÉTECTION SURVEILLANCE / ÉCOUTE / PIRATAGE
# ════════════════════════════════════════════════════════════════

detect_surveillance() {
    show_banner
    echo -e "${RED}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}    DÉTECTION SURVEILLANCE / ÉCOUTE / PIRATAGE${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════${NC}\n"

    local threat_score=0
    local threats=()

    info "🔍 Recherche d'Applications Espion"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    # 'pm list packages' peut échouer silencieusement sur certains
    # appareils (restrictions Samsung Knox / SELinux / transaction Binder
    # trop grosse), en renvoyant un message d'erreur au lieu de la liste.
    # On le récupère UNE SEULE fois et on vérifie qu'il est valide avant
    # de s'en servir pour la détection spyware/apps cachées.
    PM_LIST=$(pm list packages 2>&1)
    PM_EXIT=$?
    PM_OK=true
    if [ $PM_EXIT -ne 0 ]; then
        PM_OK=false
    fi
    if echo "$PM_LIST" | grep -qiE "Failure calling service|Exception|Failed transaction|Can't find service|Permission denied|command not found|not found"; then
        PM_OK=false
    fi
    if [ -z "$PM_LIST" ]; then
        PM_OK=false
    fi

    # NOTE: les vrais spywares commerciaux masquent/renomment souvent leur
    # package. Cette liste ne détecte que les cas où l'app n'a pas été
    # dissimulée ; elle ne remplace pas un antivirus dédié.
    SPYWARE_PACKAGES=(
        "com.mspy" "com.spyzie" "com.flexispy" "com.hoverwatch"
        "com.spyera" "com.highstermobile" "com.retinax"
        "com.phonesheriff" "com.ikeymonitor" "com.spybubble" "com.copy9"
        "com.spyic" "com.cocospy" "com.spyine" "com.eyezy"
        "com.mmguardian" "com.familytime" "com.thetruthspy" "com.mobiletool"
    )

    SPYWARE_FOUND=()
    if [ "$PM_OK" = true ]; then
        for package in "${SPYWARE_PACKAGES[@]}"; do
            if echo "$PM_LIST" | grep -q "$package"; then
                SPYWARE_FOUND+=("$package")
                threat_score=$((threat_score + 10))
            fi
        done
    fi

    if [ "$PM_OK" = false ]; then
        warn "Impossible de lister les applications (pm indisponible sur cet appareil)"
        echo -e "${GRAY}  → $(echo "$PM_LIST" | head -1)${NC}"
        echo -e "${GRAY}  → Détection spyware ignorée (ni confirmée ni infirmée)${NC}"
    elif [ ${#SPYWARE_FOUND[@]} -gt 0 ]; then
        error "⚠️  SPYWARE DÉTECTÉ: ${#SPYWARE_FOUND[@]} app(s)"
        for spy in "${SPYWARE_FOUND[@]}"; do
            echo -e "  ${RED}→ $spy${NC}"
        done
        threats+=("Spyware installé")
    else
        success "Aucun spyware connu détecté"
    fi
    echo ""

    info "📞 Vérification Renvoi d'Appel / Écoute"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    echo -e "${CYAN}⚠️  Codes à tester manuellement sur le clavier:${NC}"
    echo -e "  ${YELLOW}*#21#${NC}  → Vérifier le renvoi d'appel"
    echo -e "  ${YELLOW}*#62#${NC}  → Vérifier renvoi si injoignable"
    echo -e "  ${YELLOW}*#67#${NC}  → Vérifier renvoi si occupé"
    echo -e "  ${RED}##002#${NC} → DÉSACTIVER tous les renvois"
    echo -e "  ${YELLOW}*#06#${NC}  → Afficher votre IMEI"
    echo ""

    info "👻 Recherche d'Applications Cachées"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if [ "$PM_OK" = true ]; then
        HIDDEN_COUNT=$(echo "$PM_LIST" | wc -l)
        echo -e "${GREEN}Applications installées:${NC} $HIDDEN_COUNT"

        SUSPICIOUS_SYSTEM=$(pm list packages -s 2>/dev/null \
            | grep -E "(update|media|service)" \
            | grep -Ev "com\.(google|android|samsung|sec|miui|xiaomi|huawei|honor|oppo|coloros|oneplus|vivo|qualcomm|mediatek|lge|motorola|sonyericsson)" \
            | head -5)
        if [ ! -z "$SUSPICIOUS_SYSTEM" ]; then
            warn "Apps système à vérifier (informatif, pas forcément malveillant):"
            echo "$SUSPICIOUS_SYSTEM" | while read -r app; do
                echo -e "  ${YELLOW}→ $app${NC}"
            done
            threat_score=$((threat_score + 1))
        fi
    else
        warn "Comptage des applications ignoré (pm indisponible - voir ci-dessus)"
    fi
    echo ""

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

    info "🔐 Analyse des Permissions Dangereuses"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    if command -v dumpsys >/dev/null 2>&1; then
        PKG_DUMP=$(dumpsys package 2>/dev/null)

        echo -e "${CYAN}Apps avec accès MICROPHONE:${NC}"
        MIC_COUNT=$(echo "$PKG_DUMP" | grep -c "android.permission.RECORD_AUDIO.*granted=true")
        echo -e "  ${YELLOW}$MIC_COUNT app(s) détectée(s)${NC}"

        echo -e "${CYAN}Apps avec accès LOCALISATION:${NC}"
        LOC_COUNT=$(echo "$PKG_DUMP" | grep -c "android.permission.ACCESS_FINE_LOCATION.*granted=true")
        echo -e "  ${YELLOW}$LOC_COUNT app(s) détectée(s)${NC}"

        echo -e "${CYAN}Apps avec accès SMS:${NC}"
        SMS_COUNT=$(echo "$PKG_DUMP" | grep -c "android.permission.READ_SMS.*granted=true")
        echo -e "  ${YELLOW}$SMS_COUNT app(s) détectée(s)${NC}"
        [ "$SMS_COUNT" -gt 3 ] && threat_score=$((threat_score + 2))
    else
        echo -e "${GRAY}dumpsys non disponible - vérification des permissions ignorée${NC}"
    fi
    echo ""

    info "⚡ Analyse Comportement Système"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

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
    echo ""

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

    # L'échelle affichée est plafonnée à 100 (le score brut peut dépasser
    # ce total en cas de cumul de plusieurs menaces graves)
    RAW_THREAT_SCORE=$threat_score
    [ "$threat_score" -gt 100 ] && threat_score=100

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
    fi
    echo ""

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
            echo "SCORE DE MENACE: $threat_score/100 (brut: $RAW_THREAT_SCORE)"
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
            echo "═══════════════════════════════════════════════════"
        } > "$SURV_REPORT"
        success "Rapport sauvegardé: $SURV_REPORT"
    fi

    show_signature
}

# ════════════════════════════════════════════════════════════════
#  AUTRES FONCTIONS
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

    echo -ne "${YELLOW}Sauvegarder le rapport ? (o=texte / j=JSON / n=non) : ${NC}"
    read -r SAVE_REPORT

    if [ "$SAVE_REPORT" = "o" ] || [ "$SAVE_REPORT" = "O" ]; then
        REPORT_FILE="$REPORTS_DIR/rapport_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "═══════════════════════════════════════════════════"
            echo "         RAPPORT DEKU-ANALYSE v${VERSION}"
            echo "         Date: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "═══════════════════════════════════════════════════"
            echo ""
            echo "SYSTÈME:"
            echo "  Appareil: $DEVICE_MANUFACTURER $DEVICE_BRAND $DEVICE_MODEL"
            echo "  Android: $ANDROID_VERSION (SDK $SDK_VERSION)"
            echo "  Kernel: $KERNEL"
            echo "  Architecture: $ARCH"
            echo ""
            echo "BATTERIE:"
            echo "  Niveau: ${BATTERY_LEVEL:-N/A}%"
            echo "  Statut: ${BATTERY_STATUS:-N/A}"
            echo "  Santé: ${BATTERY_HEALTH:-N/A}"
            echo ""
            echo "MÉMOIRE RAM:"
            echo "  Total: ${TOTAL_RAM_MB:-N/A} MB"
            echo "  Utilisée: ${USED_RAM_MB:-N/A} MB (${USED_PERCENT:-N/A}%)"
            echo ""
            echo "STOCKAGE (Termux):"
            df -h "$HOME" 2>/dev/null | tail -n 1 | awk '{printf "  Total: %s | Utilisé: %s (%s) | Disponible: %s\n", $2, $3, $5, $4}'
            echo ""
            echo "RÉSEAU:"
            echo "  Ping (8.8.8.8): $PING_RESULT ${PING_TIME}"
            echo ""
            echo "SÉCURITÉ:"
            echo "  Score de risque: ${risk_score:-N/A}/11"
            echo ""
            echo "═══════════════════════════════════════════════════"
        } > "$REPORT_FILE"
        success "Rapport sauvegardé: $REPORT_FILE"

    elif [ "$SAVE_REPORT" = "j" ] || [ "$SAVE_REPORT" = "J" ]; then
        REPORT_FILE="$REPORTS_DIR/rapport_$(date +%Y%m%d_%H%M%S).json"
        {
            printf '{\n'
            printf '  "version": "%s",\n' "$VERSION"
            printf '  "date": "%s",\n' "$(date '+%Y-%m-%d %H:%M:%S')"
            printf '  "systeme": {\n'
            printf '    "appareil": "%s %s %s",\n' "$DEVICE_MANUFACTURER" "$DEVICE_BRAND" "$DEVICE_MODEL"
            printf '    "android": "%s",\n' "$ANDROID_VERSION"
            printf '    "sdk": "%s",\n' "$SDK_VERSION"
            printf '    "kernel": "%s",\n' "$KERNEL"
            printf '    "architecture": "%s"\n' "$ARCH"
            printf '  },\n'
            printf '  "batterie": {\n'
            printf '    "niveau": "%s",\n' "${BATTERY_LEVEL:-N/A}"
            printf '    "statut": "%s",\n' "${BATTERY_STATUS:-N/A}"
            printf '    "sante": "%s"\n' "${BATTERY_HEALTH:-N/A}"
            printf '  },\n'
            printf '  "ram": {\n'
            printf '    "total_mb": "%s",\n' "${TOTAL_RAM_MB:-N/A}"
            printf '    "utilisee_mb": "%s",\n' "${USED_RAM_MB:-N/A}"
            printf '    "utilisee_pourcent": "%s"\n' "${USED_PERCENT:-N/A}"
            printf '  },\n'
            printf '  "reseau": {\n'
            printf '    "ping_resultat": "%s",\n' "$PING_RESULT"
            printf '    "ping_temps": "%s"\n' "$PING_TIME"
            printf '  },\n'
            printf '  "securite": {\n'
            printf '    "score_risque": "%s",\n' "${risk_score:-N/A}"
            printf '    "score_max": "11"\n'
            printf '  }\n'
            printf '}\n'
        } > "$REPORT_FILE"
        success "Rapport JSON sauvegardé: $REPORT_FILE"
    fi

    show_signature
}

device_status() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           ÉTAT RAPIDE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    BATTERY=$(get_battery_percentage)
    if [ -n "$BATTERY" ]; then
        echo -e "${GREEN}🔋 Batterie:${NC} ${BATTERY}%"
    else
        echo -e "${GREEN}🔋 Batterie:${NC} ${GRAY}indisponible${NC}"
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

    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_RAM=$((TOTAL_RAM - FREE_RAM))
        USED_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))
        TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_RAM/1024/1024}")
        echo -e "${GREEN}💾 RAM:${NC} ${USED_PERCENT}% utilisée (${TOTAL_RAM_GB} GB total)"
    fi

    STORAGE_INFO=$(df -h /sdcard 2>/dev/null | tail -n 1 | awk '{print $3 "/" $2 " (" $5 ")"}')
    echo -e "${GREEN}💿 Stockage:${NC} $STORAGE_INFO"

    echo -ne "${GREEN}🌐 Internet:${NC} "
    reset_network_cache
    test_network_basic
    if [ "$PING_RESULT" = "success" ]; then
        echo -e "${GREEN}Connecté ✓${NC} (${PING_TIME})"
    else
        echo -e "${RED}Déconnecté ✗${NC}"
    fi

    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null)
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null)
    echo -e "${GREEN}📱 Appareil:${NC} $DEVICE_MODEL"
    echo -e "${GREEN}🤖 Android:${NC} $ANDROID_VERSION"

    echo ""
    show_signature
}

monitoring_mode() {
    # Usage: monitoring_mode [interval_secondes] [duree_minutes]
    # Si les arguments sont fournis (mode CLI -m), on saute les prompts.
    local cli_interval="$1"
    local cli_duration="$2"

    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}            MODE MONITORING CONTINU${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    if [ -n "$cli_interval" ] || [ -n "$cli_duration" ]; then
        INTERVAL="${cli_interval:-60}"
        DURATION="${cli_duration:-0}"
    else
        info "Configuration du monitoring"
        echo -ne "${YELLOW}Intervalle entre les mesures (secondes) [60]: ${NC}"
        read -r INTERVAL
        INTERVAL=${INTERVAL:-60}

        echo -ne "${YELLOW}Durée totale (minutes) [0=infini]: ${NC}"
        read -r DURATION
        DURATION=${DURATION:-0}
    fi

    if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
        warn "Intervalle invalide, valeur par défaut utilisée: 60s"
        INTERVAL=60
    fi
    if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
        warn "Durée invalide, mode infini utilisé"
        DURATION=0
    fi

    LOG_FILE="$LOGS_DIR/monitor_$(date +%Y%m%d_%H%M%S).log"

    info "Logging vers: $LOG_FILE"
    info "Appuyez sur Ctrl+C pour arrêter"
    echo ""

    echo "# Deku-Analyse Monitoring Log" > "$LOG_FILE"
    echo "# Démarré: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "# Intervalle: ${INTERVAL}s" >> "$LOG_FILE"
    echo "# Format: Timestamp,Battery%,Temp°C,RAM%,Storage%,Ping(ms)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    local count=0
    local max_count=$((DURATION * 60 / INTERVAL))

    while true; do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

        BATTERY=$(get_battery_percentage)
        [ -z "$BATTERY" ] && BATTERY="N/A"

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

        echo "$TIMESTAMP,$BATTERY,$TEMP,$RAM_PERCENT,$STORAGE_PERCENT,$PING_MS" >> "$LOG_FILE"

        echo -e "${CYAN}[$TIMESTAMP]${NC} Bat:${BATTERY}% Temp:${TEMP}°C RAM:${RAM_PERCENT}% Storage:${STORAGE_PERCENT}% Ping:${PING_MS}ms"

        count=$((count + 1))

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

security_advanced_check() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}        ANALYSE DE SÉCURITÉ AVANCÉE${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    get_security_info

    info "Vérifications Additionnelles"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"

    echo -ne "${GREEN}Magisk:${NC} "
    if [ -d "/data/adb/magisk" ] || command -v magisk >/dev/null 2>&1; then
        echo -e "${YELLOW}Détecté${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    echo -ne "${GREEN}Chiffrement:${NC} "
    ENCRYPT_STATE=$(getprop ro.crypto.state 2>/dev/null)
    if [ "$ENCRYPT_STATE" = "encrypted" ]; then
        echo -e "${GREEN}Activé${NC}"
    else
        echo -e "${YELLOW}$ENCRYPT_STATE${NC}"
    fi

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
    show_signature
}

network_detailed() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           TEST RÉSEAU DÉTAILLÉ${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    info "Interfaces Réseau"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr 2>/dev/null | while read -r line; do
            echo -e "${CYAN}$line${NC}"
        done
    fi
    echo ""

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

    if command -v netstat >/dev/null 2>&1; then
        info "Ports en Écoute"
        echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
        netstat -tuln 2>/dev/null | grep LISTEN | head -n 10
        echo ""
    fi

    show_signature
}

show_reports_history() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}          HISTORIQUE DES RAPPORTS${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}\n"

    if [ ! -d "$REPORTS_DIR" ] || [ -z "$(ls -A "$REPORTS_DIR" 2>/dev/null)" ]; then
        warn "Aucun rapport trouvé"
    else
        info "Rapports disponibles:"
        echo ""
        ls -lht "$REPORTS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}'
    fi
    echo ""

    if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A "$LOGS_DIR" 2>/dev/null)" ]; then
        warn "Aucun log trouvé"
    else
        info "Logs de monitoring disponibles:"
        echo ""
        ls -lht "$LOGS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}'
    fi

    echo ""
    show_signature
}

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
    echo -e "${GREEN}Fichier config:${NC} $CONFIG_FILE"
    echo ""

    info "Seuils d'alerte actuels"
    echo -e "${WHITE}───────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Batterie faible:${NC} < ${BATTERY_LOW_THRESHOLD}%"
    echo -e "${GREEN}RAM élevée:${NC} > ${RAM_HIGH_THRESHOLD}%"
    echo -e "${GREEN}Stockage élevé:${NC} > ${STORAGE_HIGH_THRESHOLD}%"
    echo -e "${GREEN}Température CPU modérée:${NC} > ${CPU_TEMP_WARN}°C"
    echo -e "${GREEN}Température CPU élevée:${NC} > ${CPU_TEMP_HIGH}°C"
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
    echo -e "${GREEN}[1]${NC} Nettoyer les rapports anciens (>30 jours)"
    echo -e "${GREEN}[2]${NC} Nettoyer les logs anciens (>30 jours)"
    echo -e "${GREEN}[3]${NC} Installer les dépendances manquantes"
    echo -e "${GREEN}[4]${NC} Modifier les seuils d'alerte"
    echo -e "${GREEN}[0]${NC} Retour"
    echo ""

    echo -ne "${YELLOW}Choisir une action : ${NC}"
    read -r CONFIG_OPTION

    case $CONFIG_OPTION in
        1)
            info "Nettoyage des rapports..."
            find "$REPORTS_DIR" -type f -mtime +30 -delete 2>/dev/null
            success "Nettoyage terminé"
            sleep 2
            ;;
        2)
            info "Nettoyage des logs..."
            find "$LOGS_DIR" -type f -mtime +30 -delete 2>/dev/null
            success "Nettoyage terminé"
            sleep 2
            ;;
        3)
            if command -v pkg >/dev/null 2>&1; then
                info "Installation des dépendances..."
                pkg update && pkg install -y termux-api iproute2 net-tools dnsutils
                success "Installation terminée"
            else
                error "Commande 'pkg' introuvable - cette option nécessite Termux"
            fi
            sleep 2
            ;;
        4)
            echo -ne "${YELLOW}Seuil batterie faible (%) [$BATTERY_LOW_THRESHOLD]: ${NC}"
            read -r NEW_VAL
            [[ "$NEW_VAL" =~ ^[0-9]+$ ]] && BATTERY_LOW_THRESHOLD="$NEW_VAL"

            echo -ne "${YELLOW}Seuil RAM élevée (%) [$RAM_HIGH_THRESHOLD]: ${NC}"
            read -r NEW_VAL
            [[ "$NEW_VAL" =~ ^[0-9]+$ ]] && RAM_HIGH_THRESHOLD="$NEW_VAL"

            echo -ne "${YELLOW}Seuil stockage élevé (%) [$STORAGE_HIGH_THRESHOLD]: ${NC}"
            read -r NEW_VAL
            [[ "$NEW_VAL" =~ ^[0-9]+$ ]] && STORAGE_HIGH_THRESHOLD="$NEW_VAL"

            save_config
            success "Seuils sauvegardés dans $CONFIG_FILE"
            sleep 2
            ;;
    esac

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
        -r|--report)
            QUIET_MODE=true
            init_directories
            load_config
            check_dependencies || exit 1
            full_checkout
            exit 0
            ;;
        -s|--surveillance)
            QUIET_MODE=false
            init_directories
            load_config
            check_dependencies || exit 1
            detect_surveillance
            exit 0
            ;;
        -m|--monitor)
            MONITOR_TIME="$2"
            shift 2
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

init_directories
load_config
check_dependencies || exit 1

if [ -n "$MONITOR_TIME" ]; then
    if ! [[ "$MONITOR_TIME" =~ ^[0-9]+$ ]]; then
        error "Durée de monitoring invalide: $MONITOR_TIME (doit être un nombre de minutes)"
        exit 1
    fi
    monitoring_mode 60 "$MONITOR_TIME"
    exit 0
fi

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
            monitoring_mode
            read -p "Appuyez sur Entrée..." -r
            ;;
        4)
            security_advanced_check
            read -p "Appuyez sur Entrée..." -r
            ;;
        5)
            network_detailed
            read -p "Appuyez sur Entrée..." -r
            ;;
        6)
            show_reports_history
            read -p "Appuyez sur Entrée..." -r
            ;;
        7)
            show_configuration
            read -p "Appuyez sur Entrée..." -r
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
