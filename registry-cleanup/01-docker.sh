#! /usr/bin/env bash

docker run -it --rm --volume $(pwd):/root --workdir=/root python:3.13-slim bash