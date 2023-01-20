drbd builder
==============

It builds ceph debian packages to be used in debian 9 stretch machine.

When job is completed, drbd module tarball and drbd-utils debian packages 
are in /var/lib/docker/volumes/output/_data/ directory.

To Build
---------

Create an image.::

    docker build -t drbd-builder .

Run a container to build drbd.::

    docker run -v output:/output --rm drbd-builder

