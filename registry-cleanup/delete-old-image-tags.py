import argparse
import base64
import hashlib
import logging
import re
from datetime import datetime, timedelta, UTC
from uuid import uuid4

import jwt
import requests
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import (Encoding,
                                                          PublicFormat,
                                                          load_pem_private_key)
from requests import HTTPError

# Enable HTTP logging
# http_client.HTTPConnection.debuglevel = 1
# logging.basicConfig()
# logging.getLogger().setLevel(logging.DEBUG)
# requests_log = logging.getLogger("requests.packages.urllib3")
# requests_log.setLevel(logging.DEBUG)
# requests_log.propagate = True

MAX_TAGS_STORE = 3

PRIVATE_KEY_PATH = './tls.key'
TOKEN_VALID_FOR_SECONDS = 3600
SERVICE = ''
ISSUER = 'houston'
BASIC_AUTH_USERNAME = ''
BASIC_AUTH_PASSWORD = ''


def get_kid():
    with open(PRIVATE_KEY_PATH, 'rb') as crt_file:
        private_key_ = crt_file.read()
    pem_private_key = load_pem_private_key(
        private_key_,
        password=None,
        backend=default_backend()
    )
    _public_key = pem_private_key.public_key()
    der_public_key = _public_key.public_bytes(Encoding.DER, PublicFormat.SubjectPublicKeyInfo)
    sha256 = hashlib.sha256(der_public_key)
    base32_payload = base64.b32encode(sha256.digest()[:30]).decode("utf-8")  # 240bits / 8
    kid = ":".join(
        [base32_payload[i:i+4] for i in range(0, 48, 4)]
    )
    return kid


def get_private_key():
    with open(PRIVATE_KEY_PATH, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
        return private_key


def get_token_payload(client):
    #now = datetime.utcnow()
    now = datetime.now(UTC)
    token_payload = {
        'iss': ISSUER,
        'sub': 'registry',
        'aud': 'docker-registry',
        'exp': now + timedelta(seconds=TOKEN_VALID_FOR_SECONDS),
        'nbf': now,
        'iat': now,
        'jti': uuid4().hex,
        'access': [
            {"type": "repository", "name": client + "/airflow", "actions": ["pull", "*"]},
            {"type": "registry", "name": "catalog", "actions": ["*"]}]
    }
    return token_payload


def construct_token_response(client):
    token_payload = get_token_payload(client)
    token = jwt.encode(token_payload,
                       get_private_key(),
                       headers={
                           'kid': get_kid()
                       },
                       algorithm='RS256')
    return token


def get_all_tags(session, registry, client):
    """
    Get tags list
    GET ://<registry_host>/v2/<repo_name>/tags/list
    """
    response = session.get("https://{registry}/v2/{client}/airflow/tags/list".format(registry=registry, client=client), verify=False)
    if response.status_code != 200:
        return []
    response.raise_for_status()
    tags = response.json()['tags']
    
    if tags == None:
        exit("No tags listed")

    cli_tags = []
    for tag in tags:
        if re.match(r'(.*)-(\d+)', tag):
            cli_tags.append(tag)
    sorted_tags = sorted(cli_tags, key=lambda x: int(x.split('-')[-1]))
    
    if len(sorted_tags) <= 1:
        print("We found these tags in your registry response " + str(sorted_tags))
        exit("There aren't any images to clean up.")
    return sorted_tags


def keep_max_cli_tag(tags, prefix):
    fixed_prefix = str(prefix) + '-'
    if not tags:
        return tags

    max_cli_tag = max(
        (tag for tag in tags if tag.startswith(fixed_prefix)),
        key=lambda tag: int(tag.split('-')[-1])
    )

    if max_cli_tag:
        logging.info('Not deleting latest cli-* tag %r', max_cli_tag)
    return [tag for tag in tags if tag != max_cli_tag]


def get_manifesto_for_selected_tag(session, registry, client, tag):
    """
    Get manifest for selected tag
    GET ://<registry_host>/v2/<repo_name>/manifests/<tag_name>
    """
    response = session.get("https://{registry}/v2/{client}/airflow/manifests/{tag}".format(
        registry=registry, client=client, tag=tag)
    )
    response.raise_for_status()
    return response.headers['Docker-Content-Digest']


def delete_manifest(session, registry, client, digest_hash):
    """
    Delete manifest (soft delete). This request only marks image tag as deleted and doesn't delete files
    from file system. If you want to delete data from file system, run this step and go to the next step
    DELETE ://<registry_host>/v2/<repo_name>/manifests/<digest_hash>
    """
    response = session.delete(
        "https://{registry}/v2/{client}/airflow/manifests/{digest_hash}".format(
            registry=registry, client=client, digest_hash=digest_hash)
    )
    response.raise_for_status()


def main():
    parser = argparse.ArgumentParser(description="Cleanup docker registry")
    parser.add_argument("-d", "--deployment-release-name",
                        dest="client",
                        metavar="RELEASE_NAME",
                        required=True,
                        help="Airflow deployment release name, e.g. modern-rocket-1234")

    parser.add_argument("-r", "--registry",
                        dest="registry",
                        required=True,
                        help="Registry host, e.g. registry.<basedomain>")

    parser.add_argument("-p", "--image-tag-prefix",
                        dest="pattern",
                        required=True,
                        help="Release tag prefix pattern, e.g. deploy or cli")

    parser.add_argument("-n", "--dry-run",
                        action="store_true")
    args = parser.parse_args()
    client = args.client
    registry = args.registry
    prefix = args.pattern
    access_token = construct_token_response(client)
    s = requests.Session()
    s.headers.update({
        "Authorization": "Bearer %s" % access_token,
        "Accept": "application/vnd.docker.distribution.manifest.v2+json"
    })
    tags = get_all_tags(s, registry, client)
    

    # Older versions of the platform break if we delete the last/greatest cli-*
    # tag, so lets make sure we don't delete that
    tags = keep_max_cli_tag(tags, prefix)
    # calculate start/end index of tags to delete
    start_position = 0
    end_position = len(tags) - MAX_TAGS_STORE
    if end_position <= 0:
        logging.warning('This client: {} has {} tags, and we need to delete only when it is greater than {}'.format(
            client, len(tags), MAX_TAGS_STORE))
        return
    tags_to_delete = tags[start_position:end_position]
    print("Tags we are going to delete: {}".format(tags_to_delete))

    if args.dry_run:
        return

    for tag in tags_to_delete:
        try:
            digest_hash = get_manifesto_for_selected_tag(s, registry, client, tag)
            delete_manifest(s, registry, client, digest_hash)
        except HTTPError:
            logging.exception('')


if __name__ == '__main__':
    main()
