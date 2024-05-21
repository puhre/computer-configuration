# Simple tool to keep track of files

## Setup

```yaml
## ./tracked_files.yaml
#
# Syntax:
#
# <group>:
# - local: <repo-path>
#   host: <host-path>
# ...
#
# <group-1>:
# ...

generic:
  - local: files/bash_config/.bash_aliases
    host: ${HOME}/.bash_aliases
  - local: files/bash_config/.bash_secrets
    host: ${HOME}/.bash_secrets
  - local: files/bash_config/.bashrc
    host: ${HOME}/.bashrc

work:
  - local: files/work-only/print-file
    host: ${HOME}/.local/bin/print-file
  - local: files/work-only/work
    host: ${HOME}/.local/bin/work
```

## Run

```bash
# Install files from repo to computer
./run.sh --install --force <group>

# Save files top repo
./run.sh --update --force <group>
```

## Run as cron
```
0 * * * *   <path-to-project>/run.sh --update --push=from-laptop work generic <...groups>
```
