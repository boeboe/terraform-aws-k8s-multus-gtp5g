#!/bin/bash

echo "START Terraform Cloud Init"

# Update hostname
echo "[Terraform Cloud Init] Update hostname"
echo bastion > /etc/hostname
hostnamectl set-hostname bastion

# Update passwords
echo "[Terraform Cloud Init] Update passwords"
echo -e "ubuntu\nubuntu" | passwd ubuntu
echo -e "root\nroot" | passwd root

# Update and install aptitude packages
echo "[Terraform Cloud Init] Update and install aptitude packages"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
add-apt-repository -y "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com focal main"

apt-get -y update 
if [ "${APT_UPGRADE}" = true ] ; then apt-get -y upgrade ; fi
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat sshpass \
                   build-essential make git tree locate jq \
                   docker-ce docker-ce-cli containerd.io \
                   gnupg2 pass jq python3-pip terraform kubectl=${K8S_VERSION}

# Docker user and permissions
echo "[Terraform Cloud Init] Docker user and permissions"
groupadd docker
usermod -aG docker ubuntu
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# Install awscli
echo "[Terraform Cloud Init] Install awscli"
export LC_ALL=C
pip3 install awscli --upgrade

# Install Helm
echo "[Terraform Cloud Init] Install helm"
cd /tmp
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install K9s
echo "[Terraform Cloud Init] Install k9s"
cd /tmp
curl -LO https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz
tar xvfz k9s_Linux_x86_64.tar.gz
mv k9s /usr/local/bin
chmod +x /usr/local/bin/k9s

# Indicate completion of bootstrapping
echo "[Terraform Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done
