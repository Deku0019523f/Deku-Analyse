# Changelog - Deku-Analyse

## Version 2.0 - 2026-01-07

### Nouvelles Fonctionnalités
- **Mode Monitoring Continu** : Log périodique des métriques système
- **Analyse Sécurité Avancée** : Détections étendues + score de risque
- **Test Réseau Détaillé** : Multi-serveurs, interfaces, DNS, ports
- **Historique des Rapports** : Visualisation et gestion des rapports passés
- **Configuration** : Gestion dépendances et nettoyage automatique
- **Export JSON** : Format structuré en plus du texte
- **Arguments CLI** : -h, -v, -q, -r, -m pour automatisation

### Améliorations
- Vérification automatique des dépendances au démarrage
- Support API termux-battery-status
- Cache des résultats réseau (optimisation)
- Fonctions de logging colorées standardisées
- Informations enrichies : voltage, courant, swap, uptime
- Températures colorisées selon niveau
- Gestion d'erreurs renforcée
- Mode silencieux pour scripts

### Détections Ajoutées
- Magisk
- Frida (processus + port 27042)
- État chiffrement
- Samsung Knox
- Options développeur
- VPN/Proxy (interface tun)

### Corrections
- Élimination des tests ping doubles
- Meilleure gestion des commandes manquantes
- Messages d'erreur plus clairs
- Compatibilité étendue entre modèles

## Version 1.0 - 2026-01-07

### Fonctionnalités Initiales
- Checkout complet du système
- État rapide de l'appareil
- Analyse batterie, CPU, RAM, stockage
- Tests réseau basiques
- Détection root, SELinux, Xposed
- Export rapport texte
- Menu interactif coloré

---
*Développé par DarkDeku225 - t.me/DarkDeku225*
