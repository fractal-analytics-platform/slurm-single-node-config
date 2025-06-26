#!/bin/bash
set -e

if [ -n "$NODE_LABEL" ]; then
  echo "Found NODE_LABEL=$NODE_LABEL"
else
  echo "ERROR: NODE_LABEL unset. Exit."
  exit
fi

# Apt update
sudo apt update -y
sudo apt upgrade -y
echo "--- end of apt update/upgrade ---"
echo

# SLURM configuration
BASE_REPO_URL=https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/refs/heads/main
echo "Fetch $BASE_REPO_URL/config/cgroup.conf"
curl -s "$BASE_REPO_URL/config/cgroup.conf" -o /etc/slurm/cgroup.conf
echo

echo "Fetch $BASE_REPO_URL/config/slurmdbd.conf"
curl -s "$BASE_REPO_URL/config/slurmdbd.conf" -o /etc/slurm/slurmdbd.conf
echo

echo "Fetch $BASE_REPO_URL/config/$NODE_LABEL-slurm.conf"
curl -s "$BASE_REPO_URL/config/$NODE_LABEL-slurm.conf" -o /etc/slurm/slurm.conf
echo

chmod 600 /etc/slurm/slurmdbd.conf
HOSTNAME=$(hostname)
sed --in-place=".backup" -e "s/__REPLACE_HOSTNAME__/$HOSTNAME/g" /etc/slurm/slurm.conf

echo "All seems good, I will reboot in 3 seconds"
sleep 3
sudo reboot
