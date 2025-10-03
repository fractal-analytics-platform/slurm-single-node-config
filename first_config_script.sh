#!/bin/bash

set -euo pipefail

if [ -n "$NODE_LABEL" ]; then
  echo "Found NODE_LABEL=$NODE_LABEL"
else
  echo "ERROR: NODE_LABEL unset. Exit."
  exit
fi

if [ -n "$GITHUB_TAG" ]; then
  echo "Found GITHUB_TAG=$GITHUB_TAG"
else
  echo "ERROR: GITHUB_TAG unset. Exit."
  exit
fi


# Apt update
apt update -y
apt upgrade -y
apt install python3.12-venv pipx -y
apt install munge slurmd slurm-client slurmctld slurmdbd mariadb-server -y
apt install libgl1 -y   # needed for `opencv-python` package
echo "--- end of apt update/upgrade ---"
echo


# Create user
if grep fractal-worker /etc/passwd; then
    echo "fractal-worker user already exists."
else
    echo "Create 'fractal-worker' user"
    useradd fractal-worker --home-dir /home/fractal-worker --shell /bin/bash --create-home
fi
echo

# Create python3.12 venv for user and install fractal-server
sudo -u fractal-worker python3.12 -m venv /home/fractal-worker/fractal-server-env
sudo -u fractal-worker /home/fractal-worker/fractal-server-env/bin/python -m pip install fractal-server


# Make some systemd services run as `root`
for SERVICE_FILE in /usr/lib/systemd/system/slurmctld.service /usr/lib/systemd/system/slurmdbd.service; do
    echo "$SERVICE_FILE"
    if [ ! -f "$SERVICE_FILE.backup" ]; then
        cp -v "$SERVICE_FILE" "$SERVICE_FILE.backup"
    fi
    sed 's/^User=slurm/#User=slurm/' "$SERVICE_FILE" -i
    sed 's/^Group=slurm/#Group=slurm/' "$SERVICE_FILE" -i
    echo
done

# Make sure that `reboot` leads to a working SLURM state, by adding mysql and mysqld dependencies to slurmctld
SERVICE_FILE=/usr/lib/systemd/system/slurmctld.service
echo "$SERVICE_FILE"
if [ ! -f "$SERVICE_FILE.backup" ]; then
    cp -v "$SERVICE_FILE" "$SERVICE_FILE.backup"
fi
sed 's/^After=network-online.target remote-fs.target munge.service sssd.service$/After=network-online.target remote-fs.target munge.service sssd.service mysql.service mysqld.service/' "$SERVICE_FILE" -i
echo



# SLURM configuration
BASE_REPO_URL="https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/tags/$GITHUB_TAG"
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

if [ "$NODE_LABEL" == "15cpu-60ram-gpu" ] || [ "$NODE_LABEL" == "8cpu-32ram-gpu" ]; then
    echo "Fetch $BASE_REPO_URL/config/gpu-gres.conf"
    curl -s "$BASE_REPO_URL/config/gpu-gres.conf" -o /etc/slurm/gres.conf
    echo
    sed --in-place=".backup" -e "s/__REPLACE_HOSTNAME__/$HOSTNAME/g" /etc/slurm/gres.conf
fi

# directory set in slurm.conf StateSaveLocation
# should the services be ever run as a non-root user,
# this would need to be chown-ed
mkdir -p "/var/spool/slurmctld"

echo "All seems good, I will reboot in 3 seconds"
sleep 3
reboot
