#! /usr/bin/env bash

python ./delete-old-image-tags.py \
--deployment-release-name $ASTRONOMER_RELEASE_NAME \
-r $ASTRONOMER_REGISTRY \
-p deploy
