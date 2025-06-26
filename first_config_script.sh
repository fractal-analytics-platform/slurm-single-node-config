#!/bin/bash
set -e

# Check that $1 is set
if [ -n "$1" ]; then
  LABEL=$1
  echo "Setting LABEL=$LABEL"
else
  echo "ERROR: LABEL unset. Exit."
  exit
fi

# Apt update
sudo apt update -y
sudo apt upgrade -y

# SLURM configuration
BASE_REPO_URL=https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/refs/heads/main
curl "$BASE_REPO_URL/config/cgroup.conf" -o /etc/cgroup.conf
curl "$BASE_REPO_URL/config/slurmdbd.conf" -o /etc/slurmdbd.conf
curl "$BASE_REPO_URL/config/$LABEL.slurm.conf" -o /etc/slurm.conf
chmod 600 /etc/slurmdbd.conf
HOSTNAME=$(hostname)
sed --in-place=".backup" -e "s/__REPLACE_HOSTNAME__/$HOSTNAME/g" "$SLURM_CONF"

echo "All seems good, I will reboot in 3 seconds"
sleep 3
sudo reboot
