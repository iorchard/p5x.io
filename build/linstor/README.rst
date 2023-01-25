linstor builder
================

It builds linstor debian packages that can be used in debian 11 bullseye.

When job is completed, linstor debian packages 
are in /var/lib/docker/volumes/output/_data/ directory.

Build
---------

Create an image.::

    docker build -t linstor-builder .

Run a container to build linstor.::

    docker run -v output:/output --rm linstor-builder

Or just execute run.sh to build an image and run a container to build.::

    ./run.sh

