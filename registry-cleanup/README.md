This is a Python script that will connect to the Astronomer self-hosted registry pod and delete old images based on the flags you provide.

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