# slurm-single-node-config

Configuration files for single-node SLURM cluster


## STEP 1: System upgrade and setup

Write an executable `run_first_script_from_github.sh` script like
```bash
#!/bin/bash

export NODE_LABEL=15cpu-60ram
export GITHUB_TAG=v0.0.18

curl -s "https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/refs/tags/$GITHUB_TAG/first_config_script.sh" -o first_config_script.sh
bash first_config_script.sh
```
and run it with `sudo`:
```console
$ sudo ./run_first_script_from_github.sh
```

## STEP 2: GPU drivers

```bash
sudo apt install ubuntu-drivers-common
# Confirm
sudo ubuntu-drivers install --gpgpu
# Take note of which version it installs (e.g. 535, 580, ..)

# (reboot)

# Replace 580 with the versions noted above
sudo apt install nvidia-utils-580-server

# Test nvidia-smi
nvidia-smi
# Expected output starts e.g. with
# | NVIDIA-SMI 580.95.05              Driver Version: 580.95.05      CUDA Version: 13.0     |

# Test that apt updates are not broken
sudo apt update
sudo apt upgrade # should not fail
```

Actual PyTorch-based test:
```
python3.12 -m venv /tmp/venv
source /tmp/venv/bin/activate
python3.12 -m pip install torch numpy
python3.12 -c 'import torch; assert torch.cuda.is_available(); print(torch.cuda.get_device_name(0)); assert torch.cuda.get_device_name(0) == "Tesla T4";'
deactivate
rm -r /tmp/venv
```

# STEP 3: Lock the VM

Lock the VM from the openstack dashboard.


## STEP 4: SSH keys

Create the appropriate file
```bash
sudo -u fractal-worker mkdir /home/fractal-worker/.ssh
sudo -u fractal-worker touch /home/fractal-worker/.ssh/authorized_keys
```
and then populate it with appropriate keys:
* (required) vm-specific `fractal-worker` key from the main Fractal instance
* (optional) Relevant team members
