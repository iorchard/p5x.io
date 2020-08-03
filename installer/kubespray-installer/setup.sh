#!/usr/bin/env bash
#
# Installs Kubespray on remote target machines.
#

set -e -o pipefail

KS_VER="${KS_VER:-master}"

get_kubespray () {
  # Cleanup Old Kubespray Installations
  echo "Cleaning Up Old Kubespray Installation"
  rm -rf kubespray

  # Install git
  sudo apt install -y git

  # Download Kubespray
  echo "Downloading Kubespray"
  git clone https://github.com/kubernetes-incubator/kubespray.git
  pushd kubespray
  git checkout "$KS_VER"
  popd
}

prepare_kubespray () {
  # check ${NODES} has entries.
  if [ x"${#NODES[@]}" == x"0" ]
  then
    echo "NODES should be defined."
    exit 1
  fi
  # install python3-venv if pyvenv not found.
  if ! which pyvenv
  then
    sudo apt install -y python3-venv
  fi
  # create a virtualenv with specific packages, if it doesn't exist
  if [ ! -x "ks_venv/bin/activate" ]
  then
    python3 -m venv ks_venv
    # shellcheck disable=SC1091
    source ks_venv/bin/activate

    pip install -U pip  # upgrade pip
    pip install wheel   # to avoid bdist error while compiling modules
    pip install -r kubespray/requirements.txt
  else
    # shellcheck disable=SC1091
    source ks_venv/bin/activate
  fi


  # Generate inventory and var files
  echo "Generating The Inventory File"

  rm -rf "inventories/${DEPLOYMENT_NAME}"
  mkdir -p "inventories/${DEPLOYMENT_NAME}"

  cp -r kubespray/inventory/sample/group_vars "inventories/${DEPLOYMENT_NAME}/group_vars"
  CONFIG_FILE="inventories/${DEPLOYMENT_NAME}/inventory.yml" python3 kubespray/contrib/inventory_builder/inventory.py "${NODES[@]}"
}

replace_hostname () {
  # check ${NODES} has entries.
  if [ x"${#NODES[@]}" == x"0" ]
  then
    echo "NODES should be defined."
    exit 1
  fi
  # kubespray changes hostname to node{1,2,3,...}
  # Replace them to real hostnames
  CONFIG_FILE="inventories/${DEPLOYMENT_NAME}/inventory.yml"
  echo ${NODES[*]}
  for i in ${!NODES[*]}
  do
    sed -i s/node$(($i+1)):/${NODES[$i]}:/g ${CONFIG_FILE}
  done
}

preflight_kubespray () {
  # Go to python virtual env
  source ks_venv/bin/activate

  # Create vault file.
  read -s -p 'ssh password: ' SSHPASS; echo ""
  read -s -p 'sudo password: ' SUDOPASS; echo ""
  echo "ssh_pass: $SSHPASS" \
      > inventories/${DEPLOYMENT_NAME}/group_vars/all/vault.yml
  echo -n "sudo_pass: $SUDOPASS" \
      >> inventories/${DEPLOYMENT_NAME}/group_vars/all/vault.yml
  head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8 > .vaultpass
  ansible-vault encrypt --vault-password-file .vaultpass \
      inventories/${DEPLOYMENT_NAME}/group_vars/all/vault.yml
  # Add configuration to inventory
  echo ${NODES[*]}
  ansible-playbook \
      -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" \
      --vault-password-file .vaultpass \
      --extra-vars "deployment_name=${DEPLOYMENT_NAME}" \
      --extra-vars=@config.yml \
      k8s-configs.yaml

  # Set up target nodes
  echo "Installing Prerequisites On Target Nodes"
  ansible-playbook \
      -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" \
      --vault-password-file .vaultpass \
      k8s-requirements.yaml 
}

install_kubespray () {
  # Go to python virtual env
  source ks_venv/bin/activate

  # Run Kubespray
  echo "Running Kubespray"
  ansible-playbook \
      -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" \
      --vault-password-file .vaultpass \
      -b -v kubespray/cluster.yml

  # Remove vault password and vault yaml
  #rm -f inventories/${DEPLOYMENT_NAME}/group_vars/all/vault.yml .vaultpass
}

reset_kubespray () {
  # Go to python virtual env
  source ks_venv/bin/activate
  # Reset Kubespray
  echo "Resetting Kubespray"
  ansible-playbook \
      -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" \
      --vault-password-file .vaultpass \
      -b -v kubespray/reset.yml
}

#
# Exports the Kubespray Config Location
#
source_kubeconfig () {

  sudo chown -R ${UID}:${GROUPS} ${PWD}
  kubeconfig_path="inventories/${DEPLOYMENT_NAME}/artifacts/admin.conf"

  if [ -f "$kubeconfig_path" ]
  then
    # these options are annoying outside of scripts
    set +e +u +o pipefail
    cp $kubeconfig_path ${HOME}/.kubeconfig-${DEPLOYMENT_NAME}
    if ! grep KUBECONFIG ${HOME}/.bashrc
    then
      echo "setting KUBECONFIG=${HOME}/.kubeconfig-${DEPLOYMENT_NAME}"
      echo "export KUBECONFIG=${HOME}/.kubeconfig-${DEPLOYMENT_NAME}" >> ${HOME}/.bashrc
    else
      echo "KUBECONFIG is already in ${HOME}/.bashrc"
    fi
  else
    echo "kubernetes admin.conf not found at: '$kubeconfig_path'"
    exit 1
  fi
}

#
# Checks if an arbitrary cluster name is given during specifc
# operations.
#
check_cluster_name () {
  if [ -z "$DEPLOYMENT_NAME" ]
    then
      echo "Missing option: clustername" >&2
      echo " "
      display_help
      exit -1
    fi
}

#
# Displays the help menu.
#
display_help () {
  echo "Usage: $0 {-g|-p|-r|-P|-i|-R|-s|-h} [clustername] [ip...|hostname...]" >&2
  echo " "
  echo "   -h, --help              Display this help message."
  echo "   -g, --get               Get Kubespray git source."
  echo "   -p, --prepare           Prepare kubespray."
  echo "   -r, --replace           Replace hostnames."
  echo "   -P, --preflight         Pre-flight kubespray."
  echo "   -i, --install           Run Kubespray on <clustername>."
  echo "   -R, --reset             Reset Kubespray on <clustername>"
  echo "   -s, --source            Source the Kubectl config for <clustername>"
  echo " "
  echo "   clustername             An arbitrary name representing the cluster"
  echo "   ip                      The IP address of the remote node(s)"
  echo " "
  echo "Example usages:"
  echo "   KS_VER=<kubespray_release_version> ./setup.sh -g clustername"
  echo "   ./setup.sh -p clustername [ip...]"
  echo "   ./setup.sh -r clustername [hostname...]"
  echo "   SSH_USER=<ssh_user> KUBE_VER=<k8s_version> CILIUM_VER=<cilium_version> ./setup.sh -P clustername"
  echo "   ./setup.sh -i clustername"
  echo "   ./setup.sh -R clustername"
  echo "   ./setup.sh -s clustername"
}

#
# Init
#
if [ $# -lt 2 ]
then
  display_help
  exit 0
fi

CLI_OPT=$1
DEPLOYMENT_NAME=$2
shift 2
NODES=("${@}")

while :
do
  case $CLI_OPT in
    -g | --get)
        get_kubespray
        exit 0
        ;;
    -p | --prepare)
        check_cluster_name
        prepare_kubespray
        exit 0
        ;;
    -r | --replace)
        check_cluster_name
        replace_hostname
        exit 0
        ;;
    -P | --preflight)
        check_cluster_name
        preflight_kubespray
        exit 0
        ;;
    -i | --install)
        check_cluster_name
        install_kubespray
        exit 0
        ;;
    -R | --reset)
        check_cluster_name
        reset_kubespray
        exit 0
        ;;
    -h | --help)
        display_help
        exit 0
        ;;
    -s | --source)
        check_cluster_name
        source_kubeconfig
        break
        ;;
    --) # End of all options
        shift
        break
        ;;
    *)
        echo Error: Unknown option: "$CLI_OPT" >&2
        echo " "
        display_help
        exit -1
        ;;
  esac
done
