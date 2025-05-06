This repo contains scripts that Astronomer customers might want to use when interacting with the Astronomer Support team.

## get-all-logs.sh

This script uses the `kubectl logs` command to gather logs from the platform containers that Astronomer support is usually interested in. The script will put all the collected logs in a directory called `logs` inside your working directory. If the `logs` directory already exists in your working directory, the script will delete it.

### Dependencies
* A functioning kubeconfig
* `kubectl`
* The `openssl` CLI (to generate random characters for file naming reasons)


## registry-cleanup

This is a Python script that will connect to the Astronomer self-hosted registry pod and delete old images based on the flags you provide. You can find full instructions here
https://support.astronomer.io/hc/en-us/articles/4416479648275-How-to-clean-up-the-Astronomer-registry

*NOTE - Unless your Astronomer platform uses public certs or you install your root CA into the Docker container, you will see TLS verification warnings. If your laptop has the root CA installed, you could make a virtual env instead of using Docker and that will prevent the TLS verification warnings*


## 00-get-key.sh

Run this to collect the TLS key from the registry pod. You'll need this to form requests to the registry.

## 01-docker.sh

Using Docker helps ensure that the same Python environment gets used every time

## 02-dependencies.sh

It's just a pip3 install

## 03-run-script.sh

This will run `delete-old-image-tags.py` to do the cleanup.

Depends on two environment variables
1. `ASTRONOMER_RELEASE_NAME` - the release name of the deployment who's images you want to clean up
1. `ASTRONOMER_REGISTRY` - this just needs to be `registry.$BASE_DOMAIN`

### Dependencies
* Docker (for the Python environment)
* `kubectl` to collect the key