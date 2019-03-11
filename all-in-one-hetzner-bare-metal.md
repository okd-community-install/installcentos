
# ODK on Bare Metal Deploymnet

This  manual describes a way of how to run the installation on a bare metal hetzner box.

It is meant to complement [Hetzner OCP](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp), where a cluster like setup is not needed or appropriate.

This is done without installing the logging/metrics System, because there is no value added when someone needs an environment for app-developement/customising apps or executing a showcase.
The purpose is to have a real openshift smell like development-sandbox but not a fully blown cluster.

The procedure can be executed in approximatly 3-4h, where attention is needed for 1-2h approx.


#Install Base OS

There is a preparation to be achieved.

This is taken from:

https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp#install-instructions

The simplest way of partitioning is:
```
DRIVE1 /dev/sda
DRIVE2 /dev/sdb
SWRAID 1
SWRAIDLEVEL 1
BOOTLOADER grub
HOSTNAME CentOS-76-64-minimal
PART /boot ext3     512M
PART lvm   vg0       all

LV vg0   root   /       ext4     200G
LV vg0   swap   swap    swap       5G
LV vg0   tmp    /tmp    ext4      10G
LV vg0   home   /home   ext4      40G


IMAGE /root/.oldroot/nfs/install/../images/CentOS-76-64-minimal.tar.gz
```

for a box 2*2GB. If the imgge is not avalilible just check for the next version of CentOS.


After installing the the image the first to to is enable SELinux, as it comes disabled:

```
vi /etc/selinux/config
SELINUX=enforcing
reboot/login
getenfore
-> Enfocing


yum -y install screen git


```

# Install ODK


Please read the section upfront but shlighly change some commands

https://github.com/gshipley/installcentos

Skip 2.

and clone with:

```
#Use your Git-Fork or use:
export GIT_BASE_DIR=https://github.com/gshipley/installcentos

git clone $GIT_BASE_DIR
```
Then Export the follwing variables; these will take control over the
process os installation where relevant:

```
export METRICS="False"
export LOGGING="False"
```

3. Execute the installation script

```
cd installcentos
./install-openshift.sh
```

# Secure System with Firewall

While the installation is running you might want to configure the FireWall:

https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp#firewall
