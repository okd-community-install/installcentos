I have forked this repository in order to make it work on a laptop without a router available to control DNS. I am also specifically installing this on Red Hat VM instead of CentOS.

Install RedHat OKD 3.11 on your own server.  For a local only install, it is suggested that you use CDK or MiniShift instead of this repo.  This install method is targeted for a single node cluster that has a long life.

This repository is a set of scripts that will allow you easily install the latest version (3.11) of OKD in a single node fashion.  What that means is that all of the services required for OKD to function (master, node, etcd, etc.) will all be installed on a single host.  The script supports a custom hostname which you can provide using the interactive mode.

**Please do use a clean CentOS system, the script installs all necesary tools and packages including Ansible, container runtime, etc.**

## Installation

1. Create a Red Hat Developer account - https://developers.redhat.com

2. Create a Reh Hat VM and register it with your account

```
subscription-manager register
subscription-manager attach --auto
subscription-manager repos --enable=rhel-7-server-extras-rpms
```

3. Clone this repo

```
git clone https://github.com/wallyatkins/installcentos.git
```

4. Execute the installation script

```
cd installcentos
./install-openshift.sh
```

## Automation
1. Define mandatory variables for the installation process

```
# Domain name to access the cluster
$ export DOMAIN=<public ip address>.nip.io

# User created after installation
$ export USERNAME=<current user name>

# Password for the user
$ export PASSWORD=password
```

2. Define optional variables for the installation process

```
# Instead of using loopback, setup DeviceMapper on this disk.
# !! All data on the disk will be wiped out !!
$ export DISK="/dev/sda"
```

3. Run the automagic installation script as root with the environment variable in place:

```
curl https://raw.githubusercontent.com/wallyatkins/installcentos/master/install-openshift.sh | INTERACTIVE=false /bin/bash
```

## Development

For development it's possible to switch the script repo

```
# Change location of source repository
$ export SCRIPT_REPO="https://raw.githubusercontent.com/wallyatkins/installcentos/master"
$ curl $SCRIPT_REPO/install-openshift.sh | /bin/bash
```

## Uninstall

If needed OpenShift can be removed by running the uninstall adhoc ansible-playbook.

```
$ ansible-playbook -i inventory.ini openshift-ansible/playbooks/adhoc/uninstall.yml
```
