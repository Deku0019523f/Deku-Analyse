#!/data/data/com.termux/files/usr/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Fonction pour afficher le banner
show_banner() {
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
        Deku-Analyse v1.0
EOF
    echo -e "${NC}"
}

# Fonction pour afficher le menu
show_menu() {
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}[1]${NC} Checkout Complet"
    echo -e "${GREEN}[2]${NC} État de l'appareil"
    echo -e "${RED}[0]${NC} Quitter"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne "${YELLOW}CHOOSE AN OPTION : ${NC}"
}

# Fonction pour afficher la signature
show_signature() {
    echo -e "\n${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Outil : ${WHITE}Deku-Analyse${NC}"
    echo -e "${CYAN}Telegram : ${WHITE}t.me/DarkDeku225${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Fonction pour obtenir les informations système
get_system_info() {
    echo -e "${BLUE}[*]${NC} Informations Système"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Modèle
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Inconnu")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Inconnu")
    DEVICE_MANUFACTURER=$(getprop ro.product.manufacturer 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Appareil:${NC} $DEVICE_MANUFACTURER $DEVICE_BRAND $DEVICE_MODEL"

    # Version Android
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Inconnu")
    SDK_VERSION=$(getprop ro.build.version.sdk 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Android:${NC} Version $ANDROID_VERSION (SDK $SDK_VERSION)"

    # Kernel
    KERNEL=$(uname -r 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Kernel:${NC} $KERNEL"

    # Architecture
    ARCH=$(uname -m 2>/dev/null || echo "Inconnu")
    echo -e "${GREEN}Architecture:${NC} $ARCH"
    echo ""
}

# Fonction pour vérifier la batterie
get_battery_info() {
    echo -e "${BLUE}[*]${NC} État de la Batterie"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY_LEVEL=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "N/A")
        echo -e "${GREEN}Niveau:${NC} ${BATTERY_LEVEL}%"
    else
        echo -e "${RED}Niveau:${NC} Non disponible"
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
    echo ""
}

# Fonction pour vérifier la température CPU
get_cpu_temp() {
    echo -e "${BLUE}[*]${NC} Température CPU"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    TEMP_FOUND=0
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            TEMP=$(cat "$zone" 2>/dev/null)
            if [ ! -z "$TEMP" ]; then
                TEMP_C=$((TEMP / 1000))
                ZONE_TYPE=$(cat "$(dirname "$zone")/type" 2>/dev/null || echo "Unknown")
                echo -e "${GREEN}$ZONE_TYPE:${NC} ${TEMP_C}°C"
                TEMP_FOUND=1
            fi
        fi
    done

    if [ $TEMP_FOUND -eq 0 ]; then
        echo -e "${YELLOW}Aucune zone thermique détectée${NC}"
    fi
    echo ""
}

# Fonction pour vérifier la RAM
get_ram_info() {
    echo -e "${BLUE}[*]${NC} Mémoire RAM"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

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
    else
        echo -e "${RED}Informations RAM non disponibles${NC}"
    fi
    echo ""
}

# Fonction pour vérifier le stockage
get_storage_info() {
    echo -e "${BLUE}[*]${NC} Stockage"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    df -h /sdcard 2>/dev/null | tail -n 1 | awk '{
        printf "\033[0;32mTotal:\033[0m %s\n", $2
        printf "\033[0;32mUtilisé:\033[0m %s (%s)\n", $3, $5
        printf "\033[0;32mDisponible:\033[0m %s\n", $4
    }'
    echo ""
}

# Fonction pour vérifier le réseau
get_network_info() {
    echo -e "${BLUE}[*]${NC} Réseau"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Ping test
    echo -ne "${GREEN}Test Ping (8.8.8.8):${NC} "
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        PING_TIME=$(ping -c 1 8.8.8.8 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
        echo -e "${GREEN}✓ Connecté${NC} (${PING_TIME})"
    else
        echo -e "${RED}✗ Échec${NC}"
    fi

    # DNS test
    echo -ne "${GREEN}Test DNS:${NC} "
    if nslookup google.com >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Fonctionnel${NC}"
    else
        echo -e "${RED}✗ Échec${NC}"
    fi

    # VPN/Proxy detection
    echo -ne "${GREEN}VPN/Proxy:${NC} "
    if ip route show | grep -q tun; then
        echo -e "${YELLOW}Détecté (interface tun)${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # IP locale
    LOCAL_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    if [ ! -z "$LOCAL_IP" ]; then
        echo -e "${GREEN}IP Locale (WiFi):${NC} $LOCAL_IP"
    fi
    echo ""
}

# Fonction pour vérifier la sécurité
get_security_info() {
    echo -e "${BLUE}[*]${NC} Sécurité"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Root detection
    echo -ne "${GREEN}Root:${NC} "
    if [ -f "/system/xbin/su" ] || [ -f "/system/bin/su" ] || [ -f "/sbin/su" ] || command -v su >/dev/null 2>&1; then
        echo -e "${RED}Détecté${NC}"
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
    fi

    # SELinux
    echo -ne "${GREEN}SELinux:${NC} "
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX=$(getenforce 2>/dev/null || echo "Unknown")
        echo -e "${CYAN}$SELINUX${NC}"
    else
        echo -e "${YELLOW}Non disponible${NC}"
    fi

    # ADB Debug
    echo -ne "${GREEN}ADB Debug:${NC} "
    ADB_STATUS=$(getprop ro.debuggable 2>/dev/null || echo "0")
    if [ "$ADB_STATUS" = "1" ]; then
        echo -e "${YELLOW}Activé${NC}"
    else
        echo -e "${GREEN}Désactivé${NC}"
    fi

    # Frida detection
    echo -ne "${GREEN}Frida:${NC} "
    if pgrep -f frida >/dev/null 2>&1; then
        echo -e "${RED}Détecté${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi

    # Xposed detection
    echo -ne "${GREEN}Xposed:${NC} "
    if [ -f "/system/framework/XposedBridge.jar" ] || [ -f "/system/xposed.prop" ]; then
        echo -e "${YELLOW}Détecté${NC}"
    else
        echo -e "${GREEN}Non détecté${NC}"
    fi
    echo ""
}

# Fonction pour générer une recommandation
generate_recommendation() {
    echo -e "${BLUE}[*]${NC} Recommandations"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Vérifier la batterie
    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BATTERY=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        if [ ! -z "$BATTERY" ] && [ "$BATTERY" -lt 20 ]; then
            echo -e "${RED}⚠${NC} Batterie faible ($BATTERY%) - Rechargez votre appareil"
        fi
    fi

    # Vérifier la RAM
    if [ -f "/proc/meminfo" ]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        FREE_RAM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        USED_PERCENT=$((($TOTAL_RAM - $FREE_RAM) * 100 / $TOTAL_RAM))

        if [ $USED_PERCENT -gt 85 ]; then
            echo -e "${YELLOW}⚠${NC} Utilisation RAM élevée (${USED_PERCENT}%) - Fermez des applications"
        fi
    fi

    # Vérifier le stockage
    STORAGE_USED=$(df /sdcard 2>/dev/null | tail -n 1 | awk '{print $5}' | tr -d '%')
    if [ ! -z "$STORAGE_USED" ] && [ "$STORAGE_USED" -gt 90 ]; then
        echo -e "${RED}⚠${NC} Stockage presque plein (${STORAGE_USED}%) - Libérez de l'espace"
    fi

    # Vérifier la connectivité
    if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${RED}⚠${NC} Pas de connexion Internet détectée"
    fi

    echo -e "${GREEN}✓${NC} Analyse terminée avec succès"
    echo ""
}

# Option 1: Checkout Complet
full_checkout() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${WHITE}     CHECKOUT COMPLET DE L'APPAREIL${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}\n"

    get_system_info
    get_battery_info
    get_cpu_temp
    get_ram_info
    get_storage_info
    get_network_info
    get_security_info
    generate_recommendation

    # Demander si l'utilisateur veut sauvegarder
    echo -ne "${YELLOW}Voulez-vous sauvegarder le rapport ? (o/n) : ${NC}"
    read -r SAVE_REPORT

    if [ "$SAVE_REPORT" = "o" ] || [ "$SAVE_REPORT" = "O" ]; then
        REPORT_FILE="rapport_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "═══════════════════════════════════════"
            echo "    RAPPORT DEKU-ANALYSE"
            echo "    Date: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "═══════════════════════════════════════"
            echo ""
            echo "SYSTÈME:"
            echo "--------"
            echo "Appareil: $(getprop ro.product.manufacturer) $(getprop ro.product.brand) $(getprop ro.product.model)"
            echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
            echo "Kernel: $(uname -r)"
            echo ""
            echo "BATTERIE:"
            echo "---------"
            [ -f "/sys/class/power_supply/battery/capacity" ] && echo "Niveau: $(cat /sys/class/power_supply/battery/capacity)%"
            [ -f "/sys/class/power_supply/battery/status" ] && echo "Statut: $(cat /sys/class/power_supply/battery/status)"
            [ -f "/sys/class/power_supply/battery/health" ] && echo "Santé: $(cat /sys/class/power_supply/battery/health)"
            echo ""
            echo "STOCKAGE:"
            echo "---------"
            df -h /sdcard 2>/dev/null | tail -n 1
            echo ""
            echo "═══════════════════════════════════════"
            echo "Outil : Deku-Analyse"
            echo "Telegram : t.me/DarkDeku225"
            echo "═══════════════════════════════════════"
        } > "$REPORT_FILE"
        echo -e "${GREEN}✓ Rapport sauvegardé : $REPORT_FILE${NC}"
    fi

    show_signature
}

# Option 2: État de l'appareil
device_status() {
    show_banner
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${WHITE}       ÉTAT DE L'APPAREIL${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}\n"

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
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}Connecté ✓${NC}"
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

# Boucle principale
while true; do
    show_banner
    show_menu
    read -r OPTION

    case $OPTION in
        1)
            full_checkout
            echo -ne "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
            read -r
            ;;
        2)
            device_status
            echo -ne "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
            read -r
            ;;
        0)
            echo -e "${GREEN}Merci d'avoir utilisé Deku-Analyse !${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Option invalide. Veuillez réessayer.${NC}"
            sleep 2
            ;;
    esac
done
