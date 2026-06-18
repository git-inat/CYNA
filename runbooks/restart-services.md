# Runbook — Redémarrage contrôlé des services

## Objectif

Ce runbook décrit la procédure de redémarrage contrôlé des services critiques de l’infrastructure CYNA.  
L’objectif est de relancer un service sans provoquer d’interruption non maîtrisée, tout en vérifiant son état avant et après l’intervention.

## Périmètre

Les services concernés sont principalement :

| Service | Machine concernée | Rôle |
|---|---|---|
| Wazuh Manager | Serveur Wazuh | SIEM et collecte des alertes |
| Wazuh Agent | DC01, DC02, Web, Web2, HAProxy-DMZ, Syslog-GVA, Veeam | Remontée des événements |
| Nginx | Web, Web2 | Service web |
| HAProxy | HAProxy-DMZ | Reverse proxy / frontal DMZ |
| Rsyslog / Syslog | Syslog-GVA | Centralisation des journaux |
| Services Windows | DC01, DC02, Veeam | Services système et sauvegarde |

## Précautions avant intervention

Avant de redémarrer un service :

1. Vérifier s’il existe un incident en cours.
2. Prévenir l’équipe si le service est critique.
3. Vérifier l’impact potentiel sur les utilisateurs.
4. Consulter les logs récents.
5. Vérifier l’état actuel du service.
6. Éviter les redémarrages simultanés de plusieurs services critiques.
7. Conserver les preuves si le redémarrage fait suite à une alerte sécurité.

## Procédure générale Linux

### 1. Vérifier l’état du service

```bash
sudo systemctl status <nom_du_service>
```

Exemple :

```bash
sudo systemctl status wazuh-agent
sudo systemctl status nginx
sudo systemctl status haproxy
sudo systemctl status rsyslog
```

### 2. Consulter les logs récents

```bash
sudo journalctl -u <nom_du_service> --since "30 minutes ago"
```

Exemple :

```bash
sudo journalctl -u wazuh-agent --since "30 minutes ago"
```

### 3. Redémarrer le service

```bash
sudo systemctl restart <nom_du_service>
```

### 4. Vérifier que le service est actif

```bash
sudo systemctl status <nom_du_service>
```

Le résultat attendu est :

```text
active (running)
```

## Redémarrage de l’agent Wazuh Linux

```bash
sudo systemctl status wazuh-agent
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent
```

Après redémarrage, vérifier dans Wazuh Dashboard que l’agent repasse en statut **Active**.

## Redémarrage de l’agent Wazuh Windows

Ouvrir PowerShell en administrateur :

```powershell
Get-Service WazuhSvc
Restart-Service WazuhSvc
Get-Service WazuhSvc
```

Il est aussi possible de passer par l’interface graphique :

```text
services.msc
```

Puis redémarrer le service **Wazuh Agent**.

## Redémarrage de Nginx

Avant de redémarrer Nginx, tester la configuration :

```bash
sudo nginx -t
```

Si la configuration est valide :

```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

Vérifier ensuite l’accès HTTP :

```bash
curl -I http://127.0.0.1
```

ou depuis une autre machine autorisée :

```bash
curl -I http://10.0.30.1
```

## Redémarrage de HAProxy

Avant de redémarrer HAProxy, tester la configuration :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Si la configuration est valide :

```bash
sudo systemctl restart haproxy
sudo systemctl status haproxy
```

Vérifier ensuite que le frontal répond correctement :

```bash
curl -I http://127.0.0.1
```

## Redémarrage du service Syslog

Sur le serveur Syslog-GVA :

```bash
sudo systemctl status rsyslog
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
```

Vérifier les logs récents :

```bash
sudo journalctl -u rsyslog --since "30 minutes ago"
```

Générer un test local :

```bash
logger "CYNA-SYSLOG-TEST - redemarrage controle"
```

## Redémarrage des services Wazuh en environnement Docker

Si Wazuh est déployé via Docker Compose :

```bash
docker ps
docker compose ps
```

Redémarrage contrôlé :

```bash
docker compose restart
```

Vérification :

```bash
docker compose ps
docker logs --tail=50 <nom_du_conteneur>
```

Les conteneurs attendus sont généralement :

- `wazuh-manager` ;
- `wazuh-indexer` ;
- `wazuh-dashboard`.

## Redémarrage d’un service Windows

Sur DC01, DC02 ou Veeam, ouvrir PowerShell en administrateur :

```powershell
Get-Service
```

Pour redémarrer un service précis :

```powershell
Restart-Service -Name "NomDuService"
```

Vérifier ensuite son état :

```powershell
Get-Service -Name "NomDuService"
```

Pour Veeam, éviter de redémarrer les services pendant un job de sauvegarde ou de restauration.

## Vérifications après redémarrage

Après toute intervention, vérifier :

| Point vérifié | Résultat attendu |
|---|---|
| Service démarré | `active (running)` ou `Running` |
| Logs sans erreur critique | Oui |
| Agent visible dans Wazuh | Oui |
| Événements récents remontés | Oui |
| Accès applicatif fonctionnel | Oui |
| Aucun impact utilisateur majeur | Oui |

## Retour arrière

Si le service ne redémarre pas correctement :

1. Consulter les logs du service.
2. Vérifier la configuration modifiée récemment.
3. Restaurer la configuration précédente si nécessaire.
4. Redémarrer de nouveau le service.
5. Escalader à l’équipe infrastructure ou sécurité si le service reste indisponible.

Commandes utiles :

```bash
sudo journalctl -xe
sudo journalctl -u <nom_du_service> --since "1 hour ago"
```

## Traçabilité

Chaque redémarrage important doit être documenté :

| Date | Service | Machine | Motif | Résultat | Réalisé par |
|---|---|---|---|---|---|
| À compléter | À compléter | À compléter | À compléter | À compléter | À compléter |

## Conclusion

Le redémarrage d’un service critique doit être réalisé de manière contrôlée afin d’éviter les interruptions non maîtrisées.  
Cette procédure permet de vérifier l’état du service avant intervention, de réaliser le redémarrage proprement et de confirmer le retour à un fonctionnement normal.
