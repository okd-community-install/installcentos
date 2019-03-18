Install RedHat OpenShift Origin in your development box.

## Installation

1. Create a VM as explained in https://youtu.be/aqXSbDZggK4 (this video) by Grant Shipley

2. Run the automagic installation script as root, it will prompt for mandatory variables.

```
curl https://raw.githubusercontent.com/gshipley/installcentos/3.10/install-openshift.sh | /bin/bash
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
curl https://raw.githubusercontent.com/gshipley/installcentos/3.10/install-openshift.sh | INTERACTIVE=false /bin/bash
```

## Development

For development it's possible to switch the script repo

```
# Change location of source repository
$ export SCRIPT_REPO="https://raw.githubusercontent.com/gshipley/installcentos/3.10"
$ curl $SCRIPT_REPO/install-openshift.sh | /bin/bash
```

## Testing

The script is tested using the included container and the `validate.sh` script. The SSH key passed to the container needs to be imported into DigitalOcean
as `installcentos` or the `SSH_KEY_NAME` variable needs to be set.

```
make

docker run -ti -e DIGITALOCEAN_ACCESS_TOKEN="<TOKEN>" \
	-v <private key file path>:/root/.ssh/<private key file name> -v <private key file path>.pub:/root/.ssh/<private key file name>.pub \
	quay.io/osevg/installcentos-validate
```
