This decribes a way of how to run the installation on a bare metal hetzner Box.

This is done without installing the logging/metrics System, because there is absolutly no value added when
The purpose is to have a real openshift smell like development-sandbox and is siutable for presestions as well.

There is a preparation to be achieved.



This is taken from:

https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp#install-instructions

The simplest way of partitioning is:
´´´

´´´



Fst tinh to to is enable SELinux, as it comes disabled:

´´´
vi /etc/selinux/config
SELINUX=enforcing
reboot/login
getenfore
-> Enfocing


yum -y install screen git
´´´

then follow:

But skip 1.

1. Create a VM as explained in https://www.youtube.com/watch?v=ZkFIozGY0IA (this video) by Grant Shipley

2. Clone this repo

```
git clone https://github.com/gshipley/installcentos.git
```

3. Execute the installation script

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
curl https://raw.githubusercontent.com/gshipley/installcentos/master/install-openshift.sh | INTERACTIVE=false /bin/bash
```

## Development

For development it's possible to switch the script repo

```
# Change location of source repository
$ export SCRIPT_REPO="https://raw.githubusercontent.com/gshipley/installcentos/master"
$ curl $SCRIPT_REPO/install-openshift.sh | /bin/bash
```

## Testing

The script is tested using the tooling in the `validate` directory.

To use the tooling, it's required to create file `validate/env.sh` with the DigitalOcean API key

```
export DIGITALOCEAN_TOKEN=""
```

and then run `start.sh` to start the provisioning. Once the ssh is connected to the server, the
script will atatch to the `tmux` session running Ansible installer.

To destroy the infrastructure, run the `stop.sh` script.
