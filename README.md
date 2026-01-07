# Deku-Analyse

<p align="center">
  <img src="Logo.png" alt="Deku-Analyse Logo" width="200"/>
</p>

## 📋 Description

**Deku-Analyse** est un outil de diagnostic avancé pour appareils Android via Termux. Il permet d'analyser en profondeur l'état de votre téléphone sans nécessiter de root, incluant des informations système, batterie, réseau, sécurité et bien plus.

## ✨ Fonctionnalités

### 🔍 Option 1 : Checkout Complet
Diagnostic détaillé incluant :
- **Informations système** : Modèle, fabricant, version Android, kernel, architecture
- **État de la batterie** : Niveau, statut de charge, santé, température
- **Température CPU** : Monitoring des zones thermiques
- **Mémoire RAM** : Total, utilisée, disponible avec pourcentages
- **Stockage** : Espace total, utilisé et disponible
- **Réseau** : Test ping, DNS, détection VPN/Proxy, IP locale
- **Sécurité** : Détection root, bootloader, SELinux, ADB, Frida, Xposed
- **Recommandations** : Analyse intelligente avec suggestions d'amélioration
- **Rapport exportable** : Sauvegarde optionnelle en fichier texte

### ⚡ Option 2 : État de l'appareil
Vue rapide des informations essentielles :
- Niveau de batterie
- Température
- Utilisation RAM
- Stockage
- Connectivité Internet
- Modèle et version Android

## 🚀 Installation

### Prérequis
- **Termux** installé sur votre appareil Android
- Connexion Internet (pour le clonage du dépôt)

### Étapes d'installation

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

## 📖 Utilisation

### Lancement rapide
```bash
cd Deku-Analyse && ./deku-analyse.sh
```

### Navigation dans le menu
```
[1] Checkout Complet - Diagnostic détaillé avec possibilité d'export
[2] État de l'appareil - Vue rapide des informations essentielles
[0] Quitter - Fermer l'outil
```

### Exemple de rapport exporté
Lors d'un checkout complet, vous pouvez choisir de sauvegarder un rapport au format texte :
- Nom automatique : `rapport_YYYYMMDD_HHMMSS.txt`
- Contient toutes les informations système collectées
- Facilement partageable

## 🛠️ Compatibilité

- ✅ **Termux** (Android 7.0+)
- ✅ Aucune dépendance externe lourde
- ✅ Fonctionne sans root
- ✅ Compatible avec la plupart des appareils Android

## 🔒 Sécurité

Deku-Analyse :
- ❌ Ne modifie **aucun fichier système**
- ❌ Ne collecte **aucune donnée en ligne**
- ✅ Lecture seule des informations système
- ✅ Open source et auditable

## 🎨 Captures d'écran

### Banner ASCII
```
 ____       _          
|  _ \  ___| | ___   _ 
| | | |/ _ \ |/ / | | |
| |_| |  __/   <| |_| |
|____/ \___|_|\_\__,_|

__     ___                  ____    _____ 
\ \   / (_)_ __ _   _ ___  |___ \  |___ / 
 \ \ / /| | '__| | | / __|   __) |   |_ \ 
  \ V / | | |  | |_| \__ \  / __/ _ ___) |
   \_/  |_|_|   \__,_|___/ |_____(_)____/ 

             Deku-Analyse
```

## 📝 Exemples d'informations collectées

### Système
```
Appareil: Samsung Galaxy S21
Android: Version 13 (SDK 33)
Kernel: 5.10.43-android12-9-00001-g1234567890ab
Architecture: aarch64
```

### Batterie
```
Niveau: 85%
Statut: Charging
Santé: Good
Température: 32°C
```

### Réseau
```
Test Ping (8.8.8.8): ✓ Connecté (15.2 ms)
Test DNS: ✓ Fonctionnel
VPN/Proxy: Non détecté
IP Locale (WiFi): 192.168.1.42
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- 🐛 Signaler des bugs
- 💡 Proposer de nouvelles fonctionnalités
- 🔧 Soumettre des pull requests

## 📞 Contact

- **Telegram** : [@DarkDeku225](https://t.me/DarkDeku225)
- **GitHub** : [Deku0019523f](https://github.com/Deku0019523f)

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## ⚠️ Avertissement

Cet outil est fourni à des fins éducatives et de diagnostic personnel. L'auteur n'est pas responsable de l'utilisation qui en est faite.

---

<p align="center">
  <strong>Développé avec ❤️ par DarkDeku225</strong><br>
  <a href="https://t.me/DarkDeku225">Telegram</a> • 
  <a href="https://github.com/Deku0019523f">GitHub</a>
</p>
