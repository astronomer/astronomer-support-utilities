This repo contains scripts that Astronomer customers might want to use when interacting with the Astronomer Support team.

## get-all-logs.sh

This script uses the `kubectl logs` command to gather logs from the platform containers that Astronomer support is usually interested in. The script will put all the collected logs in a directory called `logs` inside your working directory. If the `logs` directory already exists in your working directory, the script will delete it.

### Dependencies
* A functioning kubeconfig
* `kubectl`
* The `openssl` CLI (to generate random characters for file naming reasons)


## registry-cleanup

This script cleans up old images from the Software registry. You can find full instructions here
https://support.astronomer.io/hc/en-us/articles/4416479648275-How-to-clean-up-the-Astronomer-registry

*NOTE - Unless your Astronomer platform uses public certs or you install your root CA into the Docker container, you will see TLS verification warnings.*

### Dependencies
* Docker (for the Python environment)
* `kubectl` to collect the key