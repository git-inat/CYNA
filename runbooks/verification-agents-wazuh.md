# Runbook — Vérification des agents Wazuh

## Objectif

Ce runbook décrit la procédure de vérification des agents Wazuh déployés sur l’infrastructure CYNA.  
L’objectif est de confirmer que les machines critiques sont bien supervisées, que les agents sont actifs et que les événements de sécurité remontent correctement dans la console Wazuh.

## Périmètre

Les vérifications concernent principalement les machines suivantes :

| Machine | Rôle | Type |
|---|---|---|
| DC01 | Contrôleur de domaine principal | Windows Server |
| DC02 | Contrôleur de domaine secondaire | Windows Server |
| Web | Serveur web DMZ | Debian Linux |
| Web2 | Serveur web secondaire DMZ | Debian Linux |
| HAProxy-DMZ | Reverse proxy / frontal DMZ | Debian Linux |
| Syslog-GVA | Centralisation des journaux | Debian Linux |
| Veeam | Serveur de sauvegarde | Windows Server |

## Pré-requis

Avant de commencer, vérifier les points suivants :

- accès à l’interface Wazuh Dashboard ;
- compte administrateur ou compte disposant des droits de consultation ;
- connectivité réseau entre les agents et le serveur Wazuh ;
- service Wazuh Manager démarré ;
- agents Wazuh installés sur les machines à superviser.

## Procédure de vérification depuis l’interface Wazuh

1. Ouvrir l’interface Wazuh Dashboard.
2. Aller dans le menu **Agents** ou **Endpoints**.
3. Vérifier que les agents attendus apparaissent dans la liste.
4. Contrôler le statut de chaque agent :
   - `Active` : agent opérationnel ;
   - `Disconnected` : agent non joignable ;
   - `Never connected` : agent installé mais jamais connecté ;
   - `Pending` : agent en attente ou problème d’enrôlement.
5. Pour chaque agent, relever les informations suivantes :
   - nom de l’agent ;
   - adresse IP ;
   - système d’exploitation ;
   - statut ;
   - date du dernier échange ;
   - version de l’agent Wazuh.

## Tableau de suivi

| Machine | IP | Agent Wazuh | Statut attendu | Statut observé | Commentaire |
|---|---|---|---|---|---|
| DC01 | 10.0.20.1 | Oui | Active | À compléter | Contrôleur de domaine principal |
| DC02 | 10.0.20.2 | Oui | Active | À compléter | Contrôleur de domaine secondaire |
| Web | 10.0.30.1 | Oui | Active | À compléter | Serveur web DMZ |
| Web2 | 10.0.30.3 | Oui | Active | À compléter | Serveur web secondaire |
| HAProxy-DMZ | 10.0.30.2 | Oui | Active | À compléter | Reverse proxy DMZ |
| Syslog-GVA | 10.0.20.20 | Oui | Active | À compléter | Serveur de centralisation des logs |
| Veeam | 10.0.20.50 | Oui | Active | À compléter | Serveur de sauvegarde |

## Vérification sur un agent Linux

Se connecter au serveur Linux concerné puis exécuter :

```bash
sudo systemctl status wazuh-agent
```

Si le service est arrêté ou en erreur :

```bash
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent
```

Consulter les journaux de l’agent :

```bash
sudo journalctl -u wazuh-agent --since "30 minutes ago"
```

Vérifier la configuration du manager Wazuh :

```bash
sudo grep -A 5 "<server>" /var/ossec/etc/ossec.conf
```

L’adresse du manager doit correspondre à l’adresse IP du serveur Wazuh utilisé dans l’infrastructure.

## Vérification sur un agent Windows

Sur un serveur Windows, ouvrir PowerShell en administrateur puis exécuter :

```powershell
Get-Service WazuhSvc
```

Si le service est arrêté ou en erreur :

```powershell
Restart-Service WazuhSvc
Get-Service WazuhSvc
```

Il est également possible de vérifier le service depuis l’outil graphique :

```text
services.msc
```

Puis rechercher le service **Wazuh Agent**.

## Tests de remontée d’événements

Pour confirmer que les événements remontent correctement dans Wazuh :

### Linux

Créer un événement contrôlé dans les journaux :

```bash
logger "CYNA-WAZUH-TEST - verification agent"
```

Puis vérifier dans Wazuh si un événement récent est visible pour l’agent concerné.

### Windows

Générer un événement simple, par exemple une connexion ou une ouverture de session, puis vérifier dans Wazuh les journaux Windows associés à l’agent.

## Points de contrôle

| Point vérifié | Résultat attendu |
|---|---|
| Agent visible dans Wazuh | Oui |
| Statut de l’agent | Active |
| Dernière connexion récente | Oui |
| Adresse IP correcte | Oui |
| Système d’exploitation correctement identifié | Oui |
| Événements récents visibles | Oui |
| Module SCA disponible | Oui |

## Actions correctives en cas d’agent inactif

Si un agent apparaît comme déconnecté :

1. Vérifier que la machine est démarrée.
2. Vérifier la connectivité réseau vers le serveur Wazuh.
3. Vérifier que le service `wazuh-agent` ou `WazuhSvc` est démarré.
4. Redémarrer l’agent.
5. Contrôler la configuration du manager dans `ossec.conf`.
6. Vérifier les règles firewall entre l’agent et le manager.
7. Réenrôler l’agent si nécessaire.

## Conclusion

La vérification régulière des agents Wazuh permet de garantir la supervision continue des serveurs critiques de l’infrastructure CYNA.  
Un agent inactif doit être traité rapidement, car il réduit la visibilité sécurité et peut empêcher la détection d’incidents sur la machine concernée.
