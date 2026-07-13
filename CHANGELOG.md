# Changelog - Deku-Analyse

## Version 2.2.0 - 2026-07-12 (Installation automatique)

### Nouveautés
- **`install.sh`** : script d'installation automatique qui gère la mise à
  jour des paquets Termux, l'installation des dépendances (`termux-api`,
  `iproute2`, `net-tools`, `dnsutils`), la vérification/l'ouverture du lien
  d'installation de l'app **Termux:API**, la configuration de la permission
  de stockage (`termux-setup-storage`), la création des dossiers
  `reports/`/`logs/`, les droits d'exécution, un fichier `.deku-config` par
  défaut, et propose la création d'une commande globale `deku-analyse`.
- README mis à jour avec la procédure d'installation en 4 commandes.
- Correction de la structure du projet documentée dans le README (elle
  mentionnait un `INSTALL.md` et un fichier `LICENSE` qui n'existent pas
  dans le dépôt réel — remplacés par `install.sh`, `LICENSE.en`/`LICENSE.fr`).

## Version 2.1.2 - 2026-07-12 (Corrections terrain - testé sur Samsung SM-A035F)

### Bugs corrigés (détectés sur appareil réel)
- **Batterie systématiquement vide ("Niveau: %")** : si `termux-battery-status` est installé mais que l'app compagnon **Termux:API** n'est pas installée/autorisée, la commande répond sans le champ attendu. Le script ne retombait alors jamais sur la lecture directe du système de fichiers. Un vrai fallback est maintenant en place partout (Checkout complet, État rapide, Monitoring), avec un message clair invitant à installer/autoriser Termux:API si aucune source ne répond.
- **"Applications installées: 1" + "Aucun spyware détecté" alors que `pm list packages` échoue** : sur certains Samsung (restriction Knox/SELinux), `pm list packages` renvoie une erreur Binder (`Failure calling service package: Failed transaction`) au lieu de la liste réelle. Le script comptait cette ligne d'erreur comme "1 application" et la recherche de spyware tombait sur une liste vide, donnant un faux résultat rassurant. Le script vérifie maintenant que `pm` répond correctement avant de compter/chercher quoi que ce soit, et affiche un avertissement explicite si ce n'est pas le cas au lieu d'un faux "aucune menace".
- **Message "Aucune zone thermique accessible"** : clarifié pour indiquer que c'est généralement une restriction SELinux/Knox du fabricant (pas un bug du script).

## Version 2.1.1 - 2026-07-12 (Corrections)

### Bugs corrigés
- **`-m/--monitor`** : l'option CLI était capturée mais jamais utilisée, elle ne faisait donc rien. Elle lance maintenant réellement un monitoring en arrière-plan avec la durée demandée.
- **Export JSON** : le prompt proposait "j pour JSON" mais rien n'était codé derrière. L'export JSON fonctionne maintenant réellement.
- **Rapport texte incomplet** : le fichier `.txt` généré ne contenait que le modèle et la batterie. Il inclut maintenant système, batterie, RAM, stockage, réseau et sécurité.
- **Cache réseau figé** : le résultat du ping (`PING_RESULT`) restait bloqué sur la première mesure de toute la session. Il est maintenant réinitialisé à chaque nouvelle vérification (état rapide, réseau).
- **Compteurs permissions (micro/localisation/SMS)** : affichaient `?` au lieu de `0` quand aucune app n'avait la permission, à cause d'une mauvaise gestion du code de sortie de `grep -c`.
- **Score de menace (surveillance)** : pouvait dépasser 100/100 par cumul de menaces. L'affichage est désormais plafonné, le score brut restant tracé dans le rapport sauvegardé.
- **Liste de spywares** : plusieurs noms de paquets contenaient des tirets, syntaxiquement impossibles pour un package Android (donc ne détectaient jamais rien) ; retirés/remplacés. `android.process.media` (package système légitime) a été retiré de la liste pour éviter un faux positif "spyware" sur la majorité des téléphones Android.
- **Détection "apps système suspectes"** trop agressive : liste blanche élargie (OEM/constructeurs) pour réduire les faux positifs, et impact réduit sur le score.
- **Divisions RAM non protégées** : `get_ram_info` pouvait planter (division par zéro / erreur bash) si `/proc/meminfo` ne contenait pas tous les champs attendus.
- **Intervalle de monitoring = 0** : provoquait une boucle sans pause ou une division par zéro ; les entrées invalides sont désormais validées avec repli sur des valeurs par défaut sûres.
- **Installation des dépendances (option Configuration)** : vérifie maintenant que `pkg` existe avant de l'appeler, pour éviter un échec silencieux hors Termux.

### Nouveautés
- **Fichier de configuration `.deku-config`** : les seuils d'alerte (batterie faible, RAM/stockage élevés, températures CPU) sont désormais configurables et persistants via le menu Configuration (option 4), au lieu d'être figés en dur dans le code.

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
