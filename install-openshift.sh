#!/bin/bash

## see: https://youtu.be/aqXSbDZggK4

## Default variables to use
export INTERACTIVE=${INTERACTIVE:="true"}
export PVS=${INTERACTIVE:="true"}
export DOMAIN=${DOMAIN:="$(curl -s ipinfo.io/ip).nip.io"}
export USERNAME=${USERNAME:="$(whoami)"}
export PASSWORD=${PASSWORD:=password}
export VERSION=${VERSION:="3.11"}
export SCRIPT_REPO=${SCRIPT_REPO:="https://raw.githubusercontent.com/gshipley/installcentos/master"}
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"}
export API_PORT=${API_PORT:="8443"}
export LETSENCRYPT=$(LETSENCRYPT:="false")
export MAIL=$(MAIL=:"example@email.com")

## Make the script interactive to set the variables
if [ "$INTERACTIVE" = "true" ]; then
	read -rp "Domain to use: ($DOMAIN): " choice;
	if [ "$choice" != "" ] ; then
		export DOMAIN="$choice";
	fi

	read -rp "Username: ($USERNAME): " choice;
	if [ "$choice" != "" ] ; then
		export USERNAME="$choice";
	fi

	read -rp "Password: ($PASSWORD): " choice;
	if [ "$choice" != "" ] ; then
		export PASSWORD="$choice";
	fi

	read -rp "OpenShift Version: ($VERSION): " choice;
	if [ "$choice" != "" ] ; then
		export VERSION="$choice";
	fi
	read -rp "IP: ($IP): " choice;
	if [ "$choice" != "" ] ; then
		export IP="$choice";
	fi

	read -rp "API Port: ($API_PORT): " choice;
	if [ "$choice" != "" ] ; then
		export API_PORT="$choice";
	fi 

	echo "Do you wish to enable HTTPS with Let's Encrypt?"
	echo "Warnings: " 
	echo "  Let's Encrypt only works if the IP is using publicly accessible IP and custom certificates."
	echo "  This feature doesn't work with OpenShift CLI for now."
	select yn in "Yes" "No"
	case $yn in
		Yes ) export LETSENCRYPT=true; break;;
		No ) export LETSENCRYPT=false; break;;
		* ) echo "Please select Yes or No.";;
	esac
	
	if [ "$LETSENCRYPT" = true ] ; then
		read -rp "Email(required for Let's Encrypt): ($MAIL): " choice;
		if [ "$choice" != "" ] ; then
			export MAIL="$choice";
		fi
	fi
	
	echo

fi

echo "******"
echo "* Your domain is $DOMAIN "
echo "* Your IP is $IP "
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "* OpenShift version: $VERSION "
echo "* Enable HTTPS with Let's Encrypt: $LETSENCRYPT "
if [ "$LETSENCRYPT" = true ] ; then
	echo "* Your email is $MAIL "
fi
echo "******"

# install updates
yum update -y

# install the following base packages
yum install -y  wget git zile nano net-tools docker-1.13.1\
				bind-utils iptables-services \
				bridge-utils bash-completion \
				kexec-tools sos psacct openssl-devel \
				httpd-tools NetworkManager \
				python-cryptography python2-pip python-devel  python-passlib \
				java-1.8.0-openjdk-headless "@Development Tools"

#install epel
yum -y install epel-release

# Disable the EPEL repository globally so that is not accidentally used during later steps of the installation
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

systemctl | grep "NetworkManager.*running" 
if [ $? -eq 1 ]; then
	systemctl start NetworkManager
	systemctl enable NetworkManager
fi

# install the packages for Ansible
yum -y --enablerepo=epel install pyOpenSSL

curl -o ansible.rpm https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.5-1.el7.ans.noarch.rpm
yum -y --enablerepo=epel install ansible.rpm

[ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

cd openshift-ansible && git fetch && git checkout release-${VERSION} && cd ..

cat <<EOD > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${IP}		$(hostname) console console.${DOMAIN}  
EOD

if [ -z $DISK ]; then 
	echo "Not setting the Docker storage."
else
	cp /etc/sysconfig/docker-storage-setup /etc/sysconfig/docker-storage-setup.bk

	echo DEVS=$DISK > /etc/sysconfig/docker-storage-setup
	echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
	echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
	echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

	systemctl stop docker

	rm -rf /var/lib/docker
	wipefs --all $DISK
	docker-storage-setup
fi

systemctl restart docker
systemctl enable docker

if [ ! -f ~/.ssh/id_rsa ]; then
	ssh-keygen -q -f ~/.ssh/id_rsa -N ""
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	ssh -o StrictHostKeyChecking=no root@$IP "pwd" < /dev/null
fi

export METRICS="True"
export LOGGING="True"

memory=$(cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:[ ]*\([0-9]*\) kB/\1/")

if [ "$memory" -lt "4194304" ]; then
	export METRICS="False"
fi

if [ "$memory" -lt "16777216" ]; then
	export LOGGING="False"
fi

curl -o inventory.download $SCRIPT_REPO/inventory.ini
envsubst < inventory.download > inventory.ini

# add proxy in inventory.ini if proxy variables are set
if [ ! -z "${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy}}}}" ]; then
	echo >> inventory.ini
	echo "openshift_http_proxy=\"${HTTP_PROXY:-${http_proxy:-${HTTPS_PROXY:-${https_proxy}}}}\"" >> inventory.ini
	echo "openshift_https_proxy=\"${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy}}}}\"" >> inventory.ini
	if [ ! -z "${NO_PROXY:-${no_proxy}}" ]; then
		__no_proxy="${NO_PROXY:-${no_proxy}},${IP},.${DOMAIN}"
	else
		__no_proxy="${IP},.${DOMAIN}"
	fi
	echo "openshift_no_proxy=\"${__no_proxy}\"" >> inventory.ini
fi

# Let's Encrypt setup
if [ "$LETSENCRYPT" = true ] ; then
	# Install CertBot
	yum install -y certbot

	# Configure Let's Encrypt certificate
	certbot certonly --manual \
			--preferred-challenges dns \
			--email $MAIL \
			--server https://acme-v02.api.letsencrypt.org/directory \
			--agree-tos \
			-d $DOMAIN \
			-d *.$DOMAIN \
			-d *.apps.$DOMAIN
	
	## Modify inventory.ini 
	# Declare usage of Custom Certificate
	# Configure Custom Certificates for the Web Console or CLI => Doesn't Work for CLI
	# Configure a Custom Master Host Certificate
	# Configure a Custom Wildcard Certificate for the Default Router
	# Configure a Custom Certificate for the Image Registry
	## See here for more explanation: https://docs.okd.io/latest/install_config/certificate_customization.html
	cat <<EOT >> inventory.ini
	
	openshift_master_overwrite_named_certificates=true
	
	openshift_master_cluster_hostname=console-internal.${DOMAIN}
	openshift_master_cluster_public_hostname=console.${DOMAIN}
	
	openshift_master_named_certificates=[{"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "names": ["console.${DOMAIN}"]}]
	
	openshift_hosted_router_certificate={"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "cafile": "/etc/letsencrypt/live/${DOMAIN}/chain.pem"}
	
	openshift_hosted_registry_routehost=registry.apps.${DOMAIN}
	openshift_hosted_registry_routecertificates={"certfile": "/etc/letsencrypt/live/${DOMAIN}/cert.pem", "keyfile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem", "cafile": "/etc/letsencrypt/live/${DOMAIN}/chain.pem"}
	openshift_hosted_registry_routetermination=reencrypt
EOT
	
	# Add Cron Task to renew certificate
	echo "@weekly  certbot renew --pre-hook=\"oc scale --replicas=0 dc router\" --post-hook=\"oc scale --replicas=1 dc router\"" > certbotcron
	crontab certbotcron
	rm certbotcron
fi

mkdir -p /etc/origin/master/
touch /etc/origin/master/htpasswd

ansible-playbook -i inventory.ini openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i inventory.ini openshift-ansible/playbooks/deploy_cluster.yml

htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}
oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

if [ "$PVS" = "true" ]; then

	curl -o vol.yaml $SCRIPT_REPO/vol.yaml

	for i in `seq 1 200`;
	do
		DIRNAME="vol$i"
		mkdir -p /mnt/data/$DIRNAME 
		chcon -Rt svirt_sandbox_file_t /mnt/data/$DIRNAME
		chmod 777 /mnt/data/$DIRNAME
		
		sed "s/name: vol/name: vol$i/g" vol.yaml > oc_vol.yaml
		sed -i "s/path: \/mnt\/data\/vol/path: \/mnt\/data\/vol$i/g" oc_vol.yaml
		oc create -f oc_vol.yaml
		echo "created volume $i"
	done
	rm oc_vol.yaml
fi

echo "******"
echo "* Your console is https://console.$DOMAIN:$API_PORT"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:$API_PORT/"
echo "******"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:$API_PORT/
