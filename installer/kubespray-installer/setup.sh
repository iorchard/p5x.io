#!/usr/bin/env bash
#
# Installs Kubespray on remote target machines.
#

set -e -o pipefail

KS_COMMIT="${KS_COMMIT:-master}"

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
  git checkout "$KS_COMMIT"
  popd
}

prepare_kubespray () {
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

  # Add configuration to inventory
  echo ${NODES[*]}
  ansible-playbook k8s-configs.yaml \
      --extra-vars "deployment_name=${DEPLOYMENT_NAME} k8s_nodes='${NODES[*]}' kubespray_remote_ssh_user='${REMOTE_SSH_USER}'"
}

replace_hostname () {
  # kubespray changes hostname to node{1,2,3,...}
  # Replace them to real hostnames
  CONFIG_FILE="inventories/${DEPLOYMENT_NAME}/inventory.yml"
  echo ${NODES[*]}
  for i in ${!NODES[*]}
  do
    echo "sed -i.bak s/node$(($i+1))/${NODES[$i]}/g ${CONFIG_FILE}"
    sed -i s/node$(($i+1)):/${NODES[$i]}:/g ${CONFIG_FILE}
  done
}

install_kubespray () {
  # Go to python virtual env
  source ks_venv/bin/activate
  # Prepare Target Machines
  echo "Installing Prerequisites On Remote Machines"
  ansible-playbook --ask-vault-pass -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" -vvvv k8s-requirements.yaml 

  # Install Kubespray
  echo "Installing Kubespray"
  ansible-playbook --ask-vault-pass -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" -v kubespray/cluster.yml
}

reset_kubespray () {
  # Go to python virtual env
  source ks_venv/bin/activate
  # Reset Kubespray
  echo "Resetting Kubespray"
  ansible-playbook -i "inventories/${DEPLOYMENT_NAME}/inventory.yml" kubespray/reset.yml -b -v
}

#
# Exports the Kubespray Config Location
#
source_kubeconfig () {

  sudo chown -R ${UID}:${GROUPS} ${PWD}
  kubeconfig_path="${PWD}/inventories/${DEPLOYMENT_NAME}/artifacts/admin.conf"

  if [ -f "$kubeconfig_path" ]
  then
    # these options are annoying outside of scripts
    set +e +u +o pipefail
    if ! grep KUBECONFIG ${HOME}/.bashrc
    then
      echo "setting KUBECONFIG=$kubeconfig_path"
      echo "export KUBECONFIG=$kubeconfig_path" >> ${HOME}/.bashrc
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
  echo "Usage: $0 {-g|-p|-r|-i|-R|-s|-h} [clustername] [ip...|hostname...]" >&2
  echo " "
  echo "   -h, --help              Display this help message."
  echo "   -g, --get               Get Kubespray git source."
  echo "   -p, --prepare           Prepare kubespray."
  echo "   -r, --replace           Replace hostnames."
  echo "   -i, --install           Install Kubespray on <clustername>"
  echo "   -R, --reset             Reset Kubespray on <clustername>"
  echo "   -s, --source            Source the Kubectl config for <clustername>"
  echo " "
  echo "   clustername             An arbitrary name representing the cluster"
  echo "   ip                      The IP address of the remote node(s)"
  echo " "
  echo "Example usages:"
  echo "   KS_COMMIT=<kubespray_release_version> ./setup.sh -g clustername"
  echo "   REMOTE_SSH_USER=orchard ./setup.sh -p clustername [ip...]"
  echo "   ./setup.sh -r clustername [hostname...]"
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
DEFAULT_NODES=(10.90.0.101 10.90.0.102 10.90.0.103)
NODES=("${@:-${DEFAULT_NODES[@]}}")

REMOTE_SSH_USER="${REMOTE_SSH_USER:-orchard}"

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
