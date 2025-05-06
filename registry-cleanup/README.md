# Docker registry cleanup command line tool


1. First, get the credentials. If your platform release name is not called "astronomer" change it in the command below

```sh
mkdir -p keys && kubectl get secret -n astronomer astronomer-tls -o jsonpath='{.data.tls\.key}' | base64 -d > keys/tls.key

```

(If you  are running from OSX, replace base64 -d​ with base64 -D​)


2. Install the required python modules:


```sh
pip3 install -r requirements.txt
```

3. Run the script with dry run to see what it would delete: (correct the registry below)

```sh
python3 ./delete-old-image-tags.py --dry-run --deployment-release-name modern-rocket-1234 -r registry.BASEDOMAIN --image-tag-prefix deploy
```

4. If the dry run looks sensible, re-run the command without `--dry-run`. This command may print the occasional 404 error, those can usually be ignored.


5. We need to tell the [Registry](https://docs.docker.com/registry/) to actually delete the now unreferenced files (again, correcting the "astronomer" namespace if it is not where your platform is deployed):


```sh
kubectl exec -n astronomer -ti $(kubectl -n astronomer get pods -l component=registry -o jsonpath="{.items[*].metadata.name}") -c registry -- registry garbage-collect /etc/docker/registry/config.yml
```

This last command should print a lot of output, but should start deleting files. There may be a long pause after it prints lines about "marking blob" before it starts deleting blobs.

If you have a number of images with a large number of tags you can repeat steps 3, 4, then run step 5 once at the end.

Once you are done you should remove the key you extracted from Kubernetes:
`rm keys/tls.key`
