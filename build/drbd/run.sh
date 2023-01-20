#!/bin/bash

docker build -t drbd-builder .
docker run -v output:/output --rm drbd-builder
