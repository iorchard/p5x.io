kubespray-installer
====================

Set up a kubernetes cluster using kubespray.

Assumption
-----------

I assume each machine has a minimal debian buster with password-enabled
sudo user and the following packages are already installed on every machine.

* ssh: required to run playbooks
* python3: required to run playbooks
* sshpass: required for ssh connection with password

Installation
--------------

Pre-requisites
++++++++++++++++

Create ssh key pair with passphrase.::

    $ ssh-keygen
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/orchard/.ssh/id_rsa):
    Created directory '/home/orchard/.ssh'.
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:


There are 5 stages to set up a kubernetes cluster.

Get stage
++++++++++

Get the latest kubespray.

    $ cd ~/p5x.io/installer/kubespray-installer
    $ ./setup.sh --get p5x.io

Prepare stage
++++++++++++++

Create ansible variables and inventories for kubespray.::

    $ ./setup.sh --prepare p5x.io <ip> ...

Replace stage
++++++++++++++

Replace hostnames in inventory file.::

    $ ./setup.sh --replace \
      p5x.io p5x-lb{1,2} p5x-m{1,2,3} p5x-w{1,2} p5x-s{1,2,3}
    # list hostnames in order of ip addresses you typed in prepare stage.

Open inventories/p5x.io/inventory.yaml and move around hostnames to the right
groups.

Preflight stage
-------------------

Run ssh-agent and add private key.::

    $ eval "$(ssh-agent -s)"
    $ ssh-add
    Enter passphrase: (Enter your passphrase of ssh key)

Edit config.yml.::

   $ vi config.yml

Run preflight ansible playbook.::

    $ ./setup.sh --preflight p5x.io
   
Install stage
-----------------

Run kubespray ansible playbook.::

    $ ./setup.sh --install p5x.io

Post install
-------------

Source kubectl config file to use kubectl command.::

    $ ./setup.sh --source p5x.io
    $ source ~/.bashrc

Reset
-------

To tear down the cluster.::

   $ ./setup.sh --reset p5x.io
