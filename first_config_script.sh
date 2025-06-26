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
echo "--- end of apt update/upgrade ---"
echo

# SLURM configuration
BASE_REPO_URL=https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/refs/heads/main
echo "Fetch $BASE_REPO_URL/config/cgroup.conf"
curl -q "$BASE_REPO_URL/config/cgroup.conf" -o /etc/slurm/cgroup.conf
echo

echo "Fetch $BASE_REPO_URL/config/slurmdbd.conf"
curl -q "$BASE_REPO_URL/config/slurmdbd.conf" -o /etc/slurm/slurmdbd.conf
echo

echo "Fetch $BASE_REPO_URL/config/$LABEL.slurm.conf"
curl -q "$BASE_REPO_URL/config/$LABEL.slurm.conf" -o /etc/slurm/slurm.conf
echo

chmod 600 /etc/slurmdbd.conf
HOSTNAME=$(hostname)
sed --in-place=".backup" -e "s/__REPLACE_HOSTNAME__/$HOSTNAME/g" /etc/slurm/slurm.conf

echo "All seems good, I will reboot in 3 seconds"
sleep 3
sudo reboot
