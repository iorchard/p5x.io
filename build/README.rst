Builder
========

It builds drbd/linstor debian packages that can be used in debian 11 bullseye.

When job is completed, linstor/drbd debian packages 
will be in output/ directory.

Build
---------

Copy .env.sample to .env.::

    $ cp .env.sample .env

Edit .env file for the latest drbd/linstor versions.

Execute run.sh to build an image and run a container to build.::

   USAGE: ./run.sh [-h|-b|-r] <target>
   
    -h --help                  Display this help message.
    -b --build <target>        Build the target.
    -r --run <target>          Run and go into the container
   
   Target
   ------
    drbd                   build drbd packages.
    linstor                build linstor packages.
   
   ex) ./run.sh --build drbd


