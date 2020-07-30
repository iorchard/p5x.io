kubespray-installer
====================

Set up a kubernetes cluster using kubespray.

There are 4 stages to install kubernetes cluster.

Get stage
----------

Get the latest kubespray release
(At the moment, v2.13.2 is the latest one at 
https://github.com/kubernetes-sigs/kubespray/releases) and 
add kubelet_max_pods to 110.::

    $ cd ~/p5x.io/installer/kubespray-installer
    $ KS_COMMIT=v2.13.2 \
        ./setup.sh --get p5x.io

    $ echo "kubelet_max_pods: 110" \
        | tee -a kubespray/roles/kubernetes/preinstall/defaults/main.yml

Prepare stage
--------------

Create ansible variables and inventories for kubespray.::

    $ REMOTE_SSH_USER=pengrix \
        ./setup.sh --prepare p5x.io 192.168.21.5{0..9}
     # if kubernetes nodes have ip range from 192.168.21.50 to 192.168.21.59.

Replace stage
---------------

Replace hostnames in inventory file.::

    $ ./setup.sh --replace \
      p5x.io p5x-lb{1,2} p5x-m{1,2,3} p5x-w{1,2} p5x-s{1,2,3}
    # list hostnames in order of ip addresses you typed in prepare stage.

Open inventories/p5x.io/inventory.yaml and move around hostnames to the right
groups.


Install stage
-----------------

Run kubespray ansible playbook.::

    $ ./setup.sh --install p5x.io

Post install
-------------

Source kubectl config file to use kubectl command.::

    $ ./setup.sh --source p5x.io
    $ source ~/.bashrc

