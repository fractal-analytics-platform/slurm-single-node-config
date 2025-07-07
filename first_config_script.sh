#!/bin/bash
set -e

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
echo "--- end of apt update/upgrade ---"
echo

apt install munge slurmd slurm-client slurmctld slurmdbd mariadb-server -y

# Install libgl1, needed for `opencv-python` Python package
apt install libgl1 -y

# Install libpmix, to avoid this `slurmd` error:
# > MPI: Loading all types
# > mpi/pmix_v5: init: (null) [0]: mpi_pmix.c:193: pmi/pmix: can not load PMIx library
# > Couldn't load specified plugin name for mpi/pmix: Plugin init() callback failed
# > MPI: Cannot create context for mpi/pmix
# > [...]
apt install libpmix-dev -y

# Install `mailutils` , to avoid "Configured MailProg is invalid" error.
# NOTE: Requires interaction (pick "local" mode).
# apt install mailutils

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


sed --in-place=".backup" -e 's/User=slurm/#User=slurm/g' /usr/lib/systemd/system/slurmdbd.service
sed --in-place=".backup" -e 's/User=slurm/#User=slurm/g' /usr/lib/systemd/system/slurmctld.service
sed --in-place=".backup" -e 's/Group=slurm/#Group=slurm/g' /usr/lib/systemd/system/slurmdbd.service
sed --in-place=".backup" -e 's/Group=slurm/#Group=slurm/g' /usr/lib/systemd/system/slurmctld.service
echo


# Make slurmctld service depend on mysql/mysqld services
sed --in-place=".backup" -e 's/After=network-online.target remote-fs.target munge.service sssd.service$/After=network-online.target remote-fs.target munge.service sssd.service mysql.service mysqld.service/g' /usr/lib/systemd/system/slurmctld.service

systemctl enable slurmd slurmdbd slurmctld slurmd munge

echo "All seems good, I will reboot in 3 seconds"
sleep 3
reboot
