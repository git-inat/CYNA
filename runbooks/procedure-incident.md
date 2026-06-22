# Runbook — Procédure de gestion d’incident sécurité

## Objectif

Ce runbook décrit la procédure à suivre en cas d’incident de sécurité détecté sur l’infrastructure CYNA.  
L’objectif est de permettre une réaction organisée, de limiter l’impact de l’incident, de préserver les preuves et de remettre les services en état de fonctionnement de manière contrôlée.

## Périmètre

Cette procédure s’applique aux incidents détectés sur les composants suivants :

- serveurs Windows : DC01, DC02, Veeam ;
- serveurs Linux : Web, Web2, HAProxy-DMZ, Syslog-GVA ;
- infrastructure réseau : OPNsense, VLAN, DMZ, flux inter-sites ;
- supervision sécurité : Wazuh, journaux système, alertes SIEM ;
- services exposés : Nginx, HAProxy, services web en DMZ.

## Exemples d’incidents couverts

| Incident | Exemple observé | Niveau |
|---|---|---|
| Brute force SSH | Tentatives répétées de connexion sur HAProxy-DMZ | Élevé |
| Comportement applicatif suspect | User-Agent malveillant ou tentative SQL injection sur Web | Élevé |
| Modification de comptes locaux | Création ou suppression d’utilisateur sur Syslog-GVA | Moyen à élevé |
| Agent Wazuh inactif | Agent déconnecté ou absence de remontée d’événements | Moyen |
| Service critique indisponible | Wazuh, HAProxy, Web ou Veeam inaccessible | Élevé |
| Mauvaise configuration réseau | Flux non autorisé entre DMZ et LAN | Critique |

## Rôles et responsabilités

| Rôle | Responsabilité |
|---|---|
| Sécurité / SecOps | Qualification de l’alerte, analyse des événements, priorisation |
| DevOps | Collecte des preuves, vérification Wazuh, correction technique |
| Infrastructure | Vérification réseau, VLAN, firewall, Proxmox, OPNsense |
| Administration utilisateurs | Vérification des postes, comptes, accès Windows et Veeam |

## Étape 1 — Détection

Les incidents peuvent être détectés par :

- alerte Wazuh ;
- logs système ;
- événement Windows ;
- journal Syslog ;
- rapport SCA ;
- anomalie réseau ;
- retour utilisateur ;
- indisponibilité d’un service.

Lorsqu’une alerte est détectée, noter immédiatement :

| Élément | Information à relever |
|---|---|
| Date et heure | À compléter |
| Machine concernée | À compléter |
| Adresse IP | À compléter |
| Type d’alerte | À compléter |
| Niveau de sévérité | À compléter |
| Source de détection | Wazuh, Syslog, Windows Event, autre |
| Personne ayant détecté l’incident | À compléter |

## Étape 2 — Qualification

Analyser l’alerte afin de déterminer s’il s’agit :

- d’un faux positif ;
- d’un test contrôlé ;
- d’un incident réel ;
- d’une mauvaise configuration ;
- d’une tentative d’attaque ;
- d’un comportement anormal nécessitant investigation.

Questions à se poser :

- La machine concernée est-elle critique ?
- L’événement est-il isolé ou répété ?
- L’adresse source est-elle connue ?
- Le comportement correspond-il à un test prévu ?
- Y a-t-il eu une réussite d’authentification après des échecs ?
- D’autres machines présentent-elles des événements similaires ?

## Étape 3 — Confinement

Si l’incident est confirmé, appliquer des mesures de confinement adaptées.

### Cas d’un serveur Linux en DMZ

Actions possibles :

- bloquer temporairement l’adresse IP source dans OPNsense ;
- limiter l’accès SSH au VLAN Management ;
- désactiver temporairement le service exposé si nécessaire ;
- vérifier les connexions actives ;
- conserver les logs avant toute suppression ou redémarrage.

Commandes utiles :

```bash
who
last
ss -tulpn
sudo journalctl --since "2 hours ago"
```

### Cas d’un serveur Windows

Actions possibles :

- vérifier les ouvertures de session ;
- contrôler les comptes récemment créés ou modifiés ;
- désactiver un compte suspect ;
- isoler temporairement le serveur si nécessaire ;
- conserver les journaux Windows.

Commandes utiles :

```powershell
Get-LocalUser
Get-LocalGroupMember Administrators
Get-EventLog -LogName Security -Newest 50
```

### Cas d’un service web exposé

Actions possibles :

- analyser les journaux Nginx ou HAProxy ;
- identifier les requêtes suspectes ;
- renforcer les en-têtes HTTP ;
- bloquer les User-Agent ou IP malveillants ;
- vérifier qu’aucune modification non autorisée n’a été réalisée.

## Étape 4 — Collecte des preuves

Avant toute correction importante, collecter les éléments suivants :

- capture de l’alerte Wazuh ;
- horodatage de l’événement ;
- logs système ;
- journaux d’authentification ;
- adresse IP source ;
- compte utilisateur concerné ;
- service ciblé ;
- commandes exécutées pendant l’analyse ;
- captures d’écran si nécessaire.

Les preuves doivent être conservées dans le dossier Git prévu :

```text
docs/tests/
docs/wazuh/
```

## Étape 5 — Analyse technique

Analyser la cause de l’incident :

| Type d’incident | Points à vérifier |
|---|---|
| Brute force SSH | accès SSH exposé, politique de mot de passe, limitation des tentatives |
| SQL injection | configuration applicative, logs web, filtrage applicatif |
| Création de compte local | origine de l’action, compte utilisé, droits administrateur |
| Agent Wazuh inactif | service agent, réseau, firewall, configuration manager |
| Service indisponible | état du service, ressources système, logs d’erreur |

## Étape 6 — Correction

Appliquer les corrections adaptées :

- restreindre les flux réseau non nécessaires ;
- limiter SSH au réseau de management ;
- mettre en place Fail2ban ou une limitation des tentatives ;
- corriger les règles firewall ;
- renforcer les politiques de mot de passe ;
- supprimer ou désactiver les comptes non autorisés ;
- appliquer les mises à jour de sécurité ;
- durcir les services exposés ;
- redémarrer les services de manière contrôlée.

## Étape 7 — Vérification après correction

Après correction, vérifier :

- absence de nouvelle alerte critique ;
- service de nouveau opérationnel ;
- agent Wazuh actif ;
- journaux correctement remontés ;
- flux réseau conformes aux règles prévues ;
- utilisateur ou service impacté de nouveau fonctionnel.

Commandes utiles :

```bash
systemctl status wazuh-agent
systemctl status nginx
systemctl status haproxy
journalctl --since "30 minutes ago"
```

Sur Windows :

```powershell
Get-Service WazuhSvc
Get-Service
```

## Étape 8 — Clôture de l’incident

Rédiger une synthèse de clôture :

| Élément | Information |
|---|---|
| Incident | À compléter |
| Date de détection | À compléter |
| Machine concernée | À compléter |
| Cause probable | À compléter |
| Impact | À compléter |
| Actions réalisées | À compléter |
| Correctif appliqué | À compléter |
| Statut final | Clos / En surveillance |
| Responsable | À compléter |

## Recommandations post-incident

Après chaque incident, il est recommandé de :

- mettre à jour les règles de filtrage ;
- documenter l’incident dans le DAT ou les runbooks ;
- ajouter les preuves dans Git ;
- revoir les règles Wazuh si nécessaire ;
- effectuer un contrôle SCA ;
- mettre à jour les procédures d’exploitation ;
- réaliser un retour d’expérience avec l’équipe.

## Conclusion

Cette procédure permet de traiter un incident sécurité de manière structurée, en partant de la détection jusqu’à la clôture.  
Elle garantit une meilleure traçabilité, limite les actions improvisées et renforce la capacité de réponse de l’équipe CYNA face aux événements détectés par Wazuh et les journaux système.
