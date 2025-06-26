# slurm-single-node-config

Configuration files for single-node SLURM cluster


## Relevant command

Write an executable `run_first_script_from_github.sh` script like
```bash
#!/bin/bash

export NODE_LABEL=15cpu-60ram
export GITHUB_TAG=v0.0.5

curl -s "https://raw.githubusercontent.com/fractal-analytics-platform/slurm-single-node-config/refs/tags/$GITHUB_TAG/first_config_script.sh" | bash
```
and run it with `sudo`:
```console
$ sudo ./run_first_script_from_github.sh
```
