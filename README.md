# Deku-Analyse

<p align="center">
  <img src="Logo.png" alt="Deku-Analyse Logo" width="200"/>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://github.com/Deku0019523f/Deku-Analyse/releases"><img src="https://img.shields.io/badge/Version-2.0-blue.svg" alt="Version"></a>
  <img src="https://img.shields.io/badge/Platform-Termux%20%7C%20Android-orange.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Bash-5.0%2B-brightgreen.svg" alt="Bash">
  <a href="https://t.me/DarkDeku225"><img src="https://img.shields.io/badge/Telegram-@DarkDeku225-blue?logo=telegram" alt="Telegram"></a>
</p>

---

## 📋 Description

**Deku-Analyse** est un outil de diagnostic avancé pour appareils Android via Termux. Il permet d'analyser en profondeur l'état de votre téléphone sans nécessiter de root, incluant des informations système, batterie, réseau, sécurité et bien plus.

## ✨ Fonctionnalités

### 🔍 Option 1 : Checkout Complet
Diagnostic détaillé incluant :
- **Informations système** : Modèle, fabricant, version Android, kernel, architecture, uptime
- **État de la batterie** : Niveau, statut de charge, santé, température, voltage, courant
- **Température CPU** : Monitoring des zones thermiques avec colorisation
- **Mémoire RAM** : Total, utilisée, disponible avec pourcentages, buffers, cache, swap
- **Stockage** : Espace total, utilisé et disponible (interne + Termux)
- **Réseau** : Test ping, DNS, détection VPN/Proxy, IP locale, gateway
- **Sécurité** : Détection root, bootloader, SELinux, ADB, Frida, Xposed, Magisk, Knox
- **Recommandations** : Analyse intelligente avec suggestions d'amélioration
- **Rapport exportable** : Sauvegarde en format texte ou JSON

### ⚡ Option 2 : État Rapide de l'appareil
Vue rapide des informations essentielles :
- Niveau de batterie 🔋
- Température 🌡️
- Utilisation RAM 💾
- Stockage 💿
- Connectivité Internet 🌐
- Modèle et version Android 📱

### 📊 Option 3 : Mode Monitoring (NOUVEAU)
Surveillance continue en temps réel :
- Configuration de l'intervalle (secondes)
- Durée limitée ou mode infini
- Log CSV avec horodatage
- Métriques : Batterie, Température, RAM, Stockage, Ping
- Sauvegarde automatique dans `logs/monitor_*.log`

### 🔒 Option 4 : Analyse de Sécurité Avancée (NOUVEAU)
Détections étendues :
- Root, Magisk, Xposed, Frida
- Bootloader, SELinux, Knox (Samsung)
- État du chiffrement
- Options développeur
- **Score de risque** (0-11 avec niveaux)
- Recommandations de sécurité personnalisées

### 🌐 Option 5 : Test Réseau Détaillé (NOUVEAU)
Analyse réseau complète :
- Tests multiples : Google DNS, Cloudflare, OpenDNS
- Liste des interfaces réseau
- Ports en écoute (si netstat disponible)
- Serveurs DNS configurés
- Gateway et IP locale

### 📁 Option 6 : Historique des Rapports (NOUVEAU)
- Consultation des rapports précédents
- Visualisation des logs de monitoring
- Gestion des fichiers générés

### ⚙️ Option 7 : Configuration (NOUVEAU)
- Vérification des dépendances
- Installation automatique des paquets manquants
- Nettoyage des fichiers anciens (>30 jours)

## 🚀 Installation

### Prérequis
- **Termux** installé sur votre appareil Android
- Connexion Internet (pour le clonage du dépôt)

### ⚡ Installation automatique (recommandé)

Le script `install.sh` s'occupe de tout : mise à jour des paquets, dépendances
(`termux-api`, `iproute2`, `net-tools`, `dnsutils`), vérification de l'app
compagnon **Termux:API**, permission de stockage, création des dossiers
`reports/`/`logs/`, droits d'exécution, fichier de configuration par défaut,
et propose même une commande globale `deku-analyse` utilisable depuis
n'importe où dans Termux.

```bash
pkg update && pkg install git -y
git clone https://github.com/Deku0019523f/Deku-Analyse.git
cd Deku-Analyse
chmod +x install.sh
./install.sh
```

Une fois terminé :
```bash
./deku-analyse.sh
```

### Étapes d'installation manuelle

1. **Installer git dans Termux** (si ce n'est pas déjà fait) :
```bash
pkg update && pkg upgrade -y
pkg install git -y
```

2. **Cloner le dépôt** :
```bash
git clone https://github.com/Deku0019523f/Deku-Analyse.git
```

3. **Accéder au dossier** :
```bash
cd Deku-Analyse
```

4. **Rendre le script exécutable** :
```bash
chmod +x deku-analyse.sh
```

5. **Lancer le script** :
```bash
./deku-analyse.sh
```

### Installation rapide (une ligne, sans install.sh)
```bash
git clone https://github.com/Deku0019523f/Deku-Analyse.git && cd Deku-Analyse && chmod +x deku-analyse.sh && ./deku-analyse.sh
```

> ℹ️ Sans `install.sh`, certaines dépendances optionnelles (`termux-api`,
> `iproute2`, `net-tools`, `dnsutils`) ne seront pas installées automatiquement
> — le script fonctionnera quand même, avec des fonctionnalités réduites
> (batterie, réseau détaillé).

## 📖 Utilisation

### Mode interactif (par défaut)
```bash
./deku-analyse.sh
```

### Options de ligne de commande
```bash
# Afficher l'aide
./deku-analyse.sh -h

# Afficher la version
./deku-analyse.sh -v

# Mode silencieux (pour automatisation)
./deku-analyse.sh -q

# Générer un rapport et quitter
./deku-analyse.sh -q -r

# Monitoring pendant 30 minutes
./deku-analyse.sh -m 30
```

### Navigation dans le menu
```
[1] Checkout Complet - Diagnostic détaillé avec possibilité d'export
[2] État de l'appareil - Vue rapide des informations essentielles
[3] Mode Monitoring - Log continu en temps réel
[4] Analyse de Sécurité Avancée - Score de risque + détections étendues
[5] Test Réseau Détaillé - Multi-serveurs, interfaces, DNS, ports
[6] Historique des Rapports - Consulter les rapports précédents
[7] Configuration - Gérer dépendances et nettoyage
[0] Quitter - Fermer l'outil
```

## 🎨 Captures d'écran

### Banner ASCII
```
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
        Deku-Analyse v2.0
```

## 📝 Exemples d'informations collectées

### Système
```
Appareil: Samsung Galaxy S21
Android: Version 13 (SDK 33)
Kernel: 5.10.43-android12-9-00001-g1234567890ab
Architecture: aarch64
Uptime: 2j 5h 32m
```

### Batterie
```
Niveau: 85%
Statut: Charging
Santé: Good
Température: 32°C
Voltage: 4.2V
Courant: 1250mA
```

### Réseau
```
Test Ping (8.8.8.8): ✓ Connecté (15.2 ms)
Test DNS: ✓ Fonctionnel
VPN/Proxy: Non détecté
IP Locale (WiFi): 192.168.1.42
Passerelle: 192.168.1.1
```

### Sécurité
```
Root: Non détecté
Bootloader: Verrouillé
SELinux: Enforcing
ADB Debug: Désactivé
Frida: Non détecté
Xposed: Non détecté
Score de Risque: 0/11 (Faible)
```

## 📊 Format des Logs de Monitoring

Les logs sont sauvegardés au format CSV :
```csv
# Deku-Analyse Monitoring Log
# Démarré: 2026-01-07 21:20:00
# Intervalle: 60s
# Format: Timestamp,Battery%,Temp°C,RAM%,Storage%,Ping(ms)

2026-01-07 21:20:00,85,42,67,45,15.2
2026-01-07 21:21:00,84,43,68,45,14.8
2026-01-07 21:22:00,84,41,66,45,16.1
```

## 🛠️ Compatibilité

- ✅ **Termux** (Android 7.0+)
- ✅ Aucune dépendance externe lourde
- ✅ Fonctionne sans root
- ✅ Compatible avec la plupart des appareils Android
- ✅ Détection automatique des commandes disponibles

## 📦 Structure du Projet

```
Deku-Analyse/
├── deku-analyse.sh    # Script principal v2.1
├── install.sh         # Installation automatique (dépendances, config, dossiers)
├── reports/           # Rapports générés (.txt, .json)
├── logs/              # Logs de monitoring (.log)
├── .deku-config       # Seuils d'alerte (généré par install.sh)
├── README.md          # Documentation
├── CHANGELOG.md       # Historique des versions
├── LICENSE.en         # Licence MIT (English)
├── LICENSE.fr         # Licence MIT (Français)
├── Logo.png           # Logo du projet
└── .gitignore         # Configuration Git
```

## 🔒 Sécurité et Confidentialité

Deku-Analyse :
- ❌ Ne modifie **aucun fichier système**
- ❌ Ne collecte **aucune donnée en ligne**
- ❌ N'envoie **aucune information** à des serveurs externes
- ✅ Lecture seule des informations système
- ✅ Toutes les analyses sont effectuées localement
- ✅ Open source et auditable
- ✅ Aucun tracking ni télémétrie

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- 🐛 Signaler des bugs via [Issues](https://github.com/Deku0019523f/Deku-Analyse/issues)
- 💡 Proposer de nouvelles fonctionnalités
- 🔧 Soumettre des pull requests
- 📖 Améliorer la documentation
- 🌍 Traduire dans d'autres langues

### Comment contribuer
1. Forkez le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add: Amazing Feature'`)
4. Pushez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📞 Contact et Support

- **Telegram** : [@DarkDeku225](https://t.me/DarkDeku225)
- **GitHub** : [Deku0019523f](https://github.com/Deku0019523f)
- **Issues** : [Signaler un problème](https://github.com/Deku0019523f/Deku-Analyse/issues)

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir les fichiers [LICENSE](LICENSE) (English) ou [LICENSE.fr](LICENSE.fr) (Français) pour plus de détails.

### Termes additionnels
1. **Usage éducatif** : Cet outil est fourni à des fins éducatives et de diagnostic uniquement
2. **Aucune garantie** : Utilisation à vos propres risques
3. **Vie privée** : Aucune collecte de données personnelles
4. **Attribution** : Merci de créditer l'auteur original lors du fork/modification

## ⚠️ Avertissement

Cet outil est fourni à des fins éducatives et de diagnostic personnel. L'auteur n'est pas responsable de l'utilisation qui en est faite. Utilisez-le de manière responsable et éthique.

## 🌟 Remerciements

Merci à tous les contributeurs et utilisateurs de Deku-Analyse !

## 📈 Statistiques

![GitHub stars](https://img.shields.io/github/stars/Deku0019523f/Deku-Analyse?style=social)
![GitHub forks](https://img.shields.io/github/forks/Deku0019523f/Deku-Analyse?style=social)
![GitHub issues](https://img.shields.io/github/issues/Deku0019523f/Deku-Analyse)

---

<p align="center">
  <strong>Développé avec ❤️ par DarkDeku225</strong><br>
  <a href="https://t.me/DarkDeku225">Telegram</a> • 
  <a href="https://github.com/Deku0019523f">GitHub</a>
</p>

<p align="center">
  <sub>Si ce projet vous aide, n'hésitez pas à lui donner une ⭐ sur GitHub !</sub>
</p>
