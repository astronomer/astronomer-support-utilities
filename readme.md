This repo contains scripts that Astronomer customers might want to use when interacting with the Astronomer Support team.

# get-all-logs.sh

This script uses the `kubectl logs` command to gather logs from the platform containers that Astronomer support is usually interested in. The script will put all the collected logs in a directory called `logs` inside your working directory. If the `logs` directory already exists in your working directory, the script will delete it.

### Dependencies
* A functioning kubeconfig
* The `openssl` CLI (to generate random characters for file naming reasons)