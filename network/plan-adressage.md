# Plan d’adressage réseau — Projet CYNA

## Objectif

Ce document présente la segmentation réseau et le plan d’adressage IP mis en place dans le cadre du projet CYNA.

L’objectif est de séparer les différentes zones de l’infrastructure afin d’améliorer la sécurité, limiter les mouvements latéraux et contrôler les flux entre les réseaux internes, la DMZ, les sites distants et le cloud Azure.

## Segmentation réseau

| Zone / VLAN | Plage IP | Rôle | Accès autorisé |
|---|---|---|---|
| VLAN 10 — Clients Genève | `10.0.10.0/24` | Postes utilisateurs du site de Genève | Accès Internet sortant filtré via OPNsense |
| VLAN 20 — Serveurs Genève | `10.0.20.0/24` | Serveurs internes : DC01, DC02, services Windows, supervision, Wazuh, Syslog | Accès depuis le LAN et l’administration uniquement |
| VLAN 30 — DMZ Genève | `10.0.30.0/24` | Services exposés : reverse proxy, HAProxy, serveurs web | Accès contrôlé depuis le LAN, l’administration et les flux autorisés depuis l’extérieur |
| VLAN 40 — Management Genève | `10.0.40.0/24` | Administration des équipements, Proxmox, OPNsense, serveurs | Accès réservé aux administrateurs uniquement |
| VLAN 110 — Clients Paris | `10.1.10.0/24` | Postes utilisateurs du site de Paris | Accès Internet sortant filtré via OPNsense |
| VLAN 120 — Serveurs Paris | `10.1.20.0/24` | Serveurs internes : WSUS, SFTP, services locaux | Accès depuis le LAN Paris et l’administration uniquement |
| VLAN 130 — Administration Paris | `10.1.30.0/24` | Réseau réservé à l’administration du site Paris | Accès réservé aux administrateurs uniquement |
| Réseau inter-sites | Tunnel IPSec | Communication sécurisée entre Genève, Paris et Azure | Flux autorisés uniquement selon les règles firewall |
| Réseau Azure | `10.2.0.0/16` | Services cloud : supervision, identité, services managés | Accès filtré depuis les sites via VPN/IPSec |

## Logique de sécurité

La segmentation réseau repose sur une séparation claire des usages. Les postes utilisateurs sont placés dans des VLAN dédiés afin de limiter leur accès direct aux serveurs critiques. Les serveurs internes sont isolés dans des VLAN serveurs afin de protéger les services sensibles comme l’Active Directory, la supervision, les sauvegardes ou les services internes.

La DMZ est utilisée pour héberger les services exposés ou semi-exposés, comme les serveurs web et le reverse proxy HAProxy. Cette zone permet de limiter l’impact d’une éventuelle compromission d’un service exposé, car les flux depuis la DMZ vers les réseaux internes sont strictement filtrés.

Les réseaux de management sont réservés à l’administration des équipements et des serveurs. Ils doivent uniquement être accessibles par les administrateurs autorisés. Cette séparation permet de réduire les risques d’accès non autorisé aux interfaces critiques comme Proxmox, OPNsense ou les serveurs d’administration.

Les communications entre Genève, Paris et Azure passent par des tunnels VPN/IPSec afin d’assurer un échange chiffré entre les différents sites. Les flux inter-sites doivent rester limités aux besoins métiers et techniques réellement nécessaires.

## Règles générales appliquées

- Les flux non nécessaires entre VLAN sont bloqués par défaut.
- Les accès d’administration sont réservés aux réseaux de management.
- La DMZ ne doit pas accéder librement aux réseaux internes.
- Les postes utilisateurs disposent principalement d’un accès Internet filtré.
- Les serveurs critiques sont accessibles uniquement depuis les réseaux autorisés.
- Les communications inter-sites sont chiffrées via VPN/IPSec.
- Les flux vers Wazuh et Syslog sont autorisés uniquement pour la remontée des journaux et événements de sécurité.

## Conclusion

Ce plan d’adressage permet de structurer l’infrastructure CYNA autour de zones réseau distinctes et sécurisées. Cette organisation facilite l’administration, améliore la lisibilité de l’architecture et renforce la posture de sécurité globale grâce à une meilleure maîtrise des flux réseau.
