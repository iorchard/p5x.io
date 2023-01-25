#!/bin/bash

docker build -t linstor-builder .
docker run -v output:/output --rm linstor-builder
