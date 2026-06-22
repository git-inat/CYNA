#!/usr/bin/env bash
# ======================================================================
# Projet CYNA - Installation agent Wazuh Linux
# Auteur : Groupe CYNA SR/CYBER
# Objet  : Installer et enregistrer un agent Wazuh sur une machine Debian/Ubuntu
# Usage  : sudo bash install-wazuh-agent.sh [IP_MANAGER_WAZUH] [NOM_AGENT]
# Exemple: sudo bash install-wazuh-agent.sh 10.0.20.3 Web
# ======================================================================

set -euo pipefail

WAZUH_MANAGER="${1:-10.0.20.3}"
AGENT_NAME="${2:-$(hostname)}"
WAZUH_VERSION="4.x"

if [[ "${EUID}" -ne 0 ]]; then
  echo "[ERREUR] Ce script doit être lancé avec les droits root ou sudo."
  exit 1
fi

echo "============================================================"
echo " Installation de l'agent Wazuh - Projet CYNA"
echo " Manager Wazuh : ${WAZUH_MANAGER}"
echo " Nom agent     : ${AGENT_NAME}"
echo "============================================================"

# Vérification OS
if [[ ! -f /etc/os-release ]]; then
  echo "[ERREUR] Système non supporté : /etc/os-release introuvable."
  exit 1
fi

. /etc/os-release
case "${ID}" in
  debian|ubuntu)
    echo "[OK] Distribution supportée : ${PRETTY_NAME}"
    ;;
  *)
    echo "[ATTENTION] Distribution non officiellement prévue par ce script : ${PRETTY_NAME}"
    echo "Le script est prévu pour Debian/Ubuntu."
    ;;
esac

# Dépendances
echo "[INFO] Installation des dépendances..."
apt-get update -y
apt-get install -y curl gnupg apt-transport-https lsb-release ca-certificates

# Ajout clé et dépôt Wazuh
echo "[INFO] Ajout du dépôt Wazuh..."
install -d -m 0755 /usr/share/keyrings
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
apt-get update -y

# Installation agent
echo "[INFO] Installation du paquet wazuh-agent..."
WAZUH_MANAGER="${WAZUH_MANAGER}" WAZUH_AGENT_NAME="${AGENT_NAME}" apt-get install -y wazuh-agent

# Configuration de sécurité : éviter une mise à jour automatique non maîtrisée de l'agent
echo "[INFO] Verrouillage du paquet wazuh-agent..."
apt-mark hold wazuh-agent >/dev/null || true

# Activation service
echo "[INFO] Activation et démarrage du service Wazuh Agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# Résumé
echo "============================================================"
echo " Installation terminée"
echo " Vérifications utiles :"
echo "   systemctl status wazuh-agent --no-pager"
echo "   grep '<address>' /var/ossec/etc/ossec.conf"
echo "   tail -n 50 /var/ossec/logs/ossec.log"
echo " Sur la console Wazuh : Agents -> vérifier que '${AGENT_NAME}' est Active"
echo "============================================================"
