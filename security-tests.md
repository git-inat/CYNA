# Tests de sécurité - Projet CYNA

## Objectif

Ce document regroupe les principaux tests de sécurité réalisés dans le cadre du projet CYNA.  
L’objectif est de vérifier la visibilité réseau, l’exposition des services, la détection Wazuh et le niveau de sécurité des composants critiques.

Les tests ont été réalisés sur l’infrastructure virtualisée Proxmox, avec une segmentation réseau basée sur plusieurs VLAN : clients, serveurs, DMZ et management. Les composants principaux testés sont les contrôleurs de domaine, les serveurs Linux en DMZ, HAProxy, Syslog-GVA, Veeam et Wazuh.

---

## Périmètre testé

| Élément | Rôle | Adresse / Zone |
|---|---|---|
| DC01 | Contrôleur de domaine principal | VLAN Serveurs Genève |
| DC02 | Contrôleur de domaine secondaire | VLAN Serveurs Genève |
| Web | Serveur web Nginx en DMZ | `10.0.30.1` |
| Web2 | Serveur web secondaire en DMZ | `10.0.30.3` |
| HAProxy-DMZ | Reverse proxy / frontal DMZ | `10.0.30.2` |
| Syslog-GVA | Centralisation des journaux | `10.0.20.20` |
| Wazuh | SIEM / supervision sécurité | `10.0.20.3` |
| Veeam | Sauvegarde et reprise d’activité | VLAN Serveurs Genève |
| OPNsense | Pare-feu, routage et filtrage inter-VLAN | Multi-zones |

---

## Test 1 - Découverte réseau avec Nmap

### Objectif

Identifier les hôtes actifs sur le VLAN serveurs Genève et vérifier que les machines attendues sont bien joignables.

### Commande utilisée

```bash
nmap -sn 10.0.20.0/24
```

### Résultat attendu

Les machines critiques du VLAN serveurs doivent être visibles, notamment DC01, DC02, OPNsense, Wazuh, Syslog-GVA et les autres serveurs hébergés sur Proxmox.

### Résultat obtenu

Le scan a permis d’identifier plusieurs hôtes actifs dans le VLAN serveurs Genève, dont les contrôleurs de domaine, la passerelle OPNsense et plusieurs machines de supervision ou d’administration.

---

## Test 2 - Scan de ports du serveur Web DMZ

### Objectif

Vérifier les ports exposés sur le serveur Web placé en DMZ.

### Commande utilisée

```bash
nmap -sT -sV -Pn 10.0.30.1
```

### Résultat attendu

Seuls les ports nécessaires au rôle du serveur Web doivent être ouverts. Le port HTTP doit être visible pour le service Nginx. L’accès SSH doit être limité au VLAN Management dans une configuration finale sécurisée.

### Résultat obtenu

Les ports `22/tcp` et `80/tcp` sont ouverts.  
Le port `80/tcp` correspond au service web Nginx exposé en DMZ.  
Le port `22/tcp` correspond à l’administration SSH et doit être restreint au réseau de management.

---

## Test 3 - Analyse applicative avec OWASP ZAP

### Objectif

Analyser le serveur Web DMZ afin d’identifier d’éventuelles vulnérabilités applicatives ou mauvaises configurations HTTP.

### Cible

```text
http://10.0.30.1
```

### Résultat attendu

Aucune vulnérabilité critique ne doit être détectée. Les éventuelles alertes doivent permettre d’identifier des axes de durcissement HTTP.

### Résultat obtenu

Le scan OWASP ZAP n’a pas identifié de vulnérabilité critique.  
Trois alertes de durcissement HTTP ont été relevées :

- absence d’en-tête `Content-Security-Policy` ;
- absence d’en-tête anti-clickjacking ;
- absence de l’en-tête `X-Content-Type-Options`.

### Correction recommandée

Renforcer la configuration Nginx/HAProxy avec des en-têtes de sécurité HTTP adaptés.

---

## Test 4 - Détection brute force SSH avec Wazuh

### Objectif

Vérifier que Wazuh détecte une tentative de brute force SSH contrôlée sur un serveur placé en DMZ.

### Cible

```text
HAProxy-DMZ - 10.0.30.2
```

### Exemple de commande de test

```bash
hydra -l cyna-test -P /tmp/cyna-pass.txt ssh://10.0.30.2
```

### Résultat attendu

Wazuh doit générer une alerte liée à des tentatives répétées de connexion SSH avec un utilisateur inexistant.

### Résultat obtenu

Wazuh a généré des alertes de niveau élevé, notamment :

- `sshd: brute force trying to get access to the system. Non existent user.` ;
- `syslog: User missed the password more than one time` ;
- `PAM: User login failed`.

La détection valide la capacité de Wazuh à identifier une attaque par force brute sur un service d’administration.

---

## Test 5 - Détection de requêtes Web suspectes

### Objectif

Vérifier que Wazuh détecte des comportements applicatifs suspects sur le serveur Web exposé en DMZ.

### Cible

```text
Web - 10.0.30.1
```

### Exemples de commandes utilisées

```bash
curl -A "Nikto CYNA-TEST" "http://10.0.30.1/admin"
curl -A "Nikto CYNA-TEST" "http://10.0.30.1/wp-admin"
curl "http://10.0.30.1/index.php?id=1' OR '1'='1"
```

### Résultat attendu

Wazuh doit remonter des alertes liées à un User-Agent suspect et à une tentative d’injection SQL simulée.

### Résultat obtenu

Wazuh a détecté :

- `Blacklisted user agent (known malicious user agent)` ;
- `SQL injection attempt` ;
- erreurs HTTP liées aux requêtes suspectes.

Ces résultats confirment que Wazuh dispose d’une visibilité sur les comportements applicatifs suspects.

---

## Test 6 - Détection de création et suppression de comptes locaux

### Objectif

Vérifier que Wazuh détecte les actions sensibles d’administration locale sur un serveur critique.

### Cible

```text
Syslog-GVA - 10.0.20.20
```

### Exemples de commandes utilisées

```bash
sudo groupadd cyna-test-group
sudo useradd cyna-test-user
sudo userdel cyna-test-user
sudo groupdel cyna-test-group
```

### Résultat attendu

Wazuh doit détecter la création et la suppression d’un utilisateur ou d’un groupe local.

### Résultat obtenu

Wazuh a détecté les événements suivants :

- `New user added to the system` ;
- `New group added to the system` ;
- `Group (or user) deleted from the system`.

Ce test confirme que les modifications sensibles réalisées sur un serveur critique sont bien tracées.

---

## Test 7 - Audit SCA Wazuh

### Objectif

Évaluer le niveau de conformité des machines supervisées par Wazuh à l’aide du module Security Configuration Assessment.

### Machines analysées

| Machine | Benchmark | Score |
|---|---|---:|
| DC01 | CIS Microsoft Windows Server 2022 Benchmark v2.0.0 | 25 % |
| DC02 | CIS Microsoft Windows Server 2022 Benchmark v2.0.0 | 25 % |
| Web | CIS Debian Linux 13 Benchmark | 42 % |
| Web2 | CIS Debian Linux 13 Benchmark | 42 % |
| HAProxy-DMZ | CIS Debian Linux 13 Benchmark | 42 % |
| Syslog-GVA | CIS Debian Linux 13 Benchmark | 43 % |
| Veeam | CIS Microsoft Windows Server 2022 Benchmark v2.0.0 | 24 % |

### Analyse

Les scores SCA montrent que le niveau de conformité est encore perfectible. Les serveurs Linux obtiennent des scores compris entre 42 % et 43 %, tandis que les serveurs Windows obtiennent des scores compris entre 24 % et 25 %. Aucun serveur n’atteint l’objectif initial de 70 % défini dans le plan de tests.

Les principaux axes d’amélioration concernent :

- les politiques de mot de passe Windows ;
- les paramètres de verrouillage de compte ;
- les permissions système ;
- les options de montage des partitions Linux ;
- la restriction des accès SSH ;
- la désactivation des services inutiles ;
- le durcissement global des serveurs.

---

## Synthèse des anomalies relevées

| ID | Description | Sévérité | Correction recommandée |
|---|---|---|---|
| SEC-001 | Brute force SSH détecté sur HAProxy-DMZ | Haute | Restreindre SSH au VLAN Management et mettre en place une limitation des tentatives |
| SEC-002 | Comportement applicatif suspect détecté sur le serveur Web | Haute | Renforcer la configuration Nginx/HAProxy et surveiller les User-Agent suspects |
| SEC-003 | Création/suppression de comptes locaux détectée sur Syslog-GVA | Moyenne | Restreindre les actions de gestion des comptes aux administrateurs autorisés |
| SEC-004 | Score SCA inférieur à l’objectif de 70 % | Moyenne | Corriger progressivement les contrôles CIS échoués |

---

## Conclusion

Les tests réalisés confirment que l’infrastructure CYNA dispose d’une segmentation réseau fonctionnelle, d’une supervision Wazuh opérationnelle et d’une capacité de détection sur plusieurs familles d’événements : brute force SSH, comportements Web suspects, modifications de comptes locaux et écarts de configuration.

Les résultats montrent également plusieurs axes d’amélioration, notamment sur le durcissement HTTP, la restriction des accès SSH et l’amélioration des scores SCA. Ces corrections permettront de renforcer progressivement la posture de sécurité globale de l’infrastructure.
