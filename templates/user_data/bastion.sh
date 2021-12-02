#!/bin/bash

echo "START F5GC Cloud Init"

# Update hostname
echo "[F5GC Cloud Init] Update hostname"
echo bastion > /etc/hostname
hostnamectl set-hostname bastion

# Update passwords
echo "[F5GC Cloud Init] Update passwords"
echo -e "ubuntu\nubuntu" | passwd ubuntu
echo -e "root\nroot" | passwd root

# Update and install aptitude packages
echo "[F5GC Cloud Init] Update and install aptitude packages"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
add-apt-repository -y "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com focal main"

apt-get -y update ; apt-get -y upgrade
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat sshpass \
                   build-essential make git tree locate \
                   docker-ce docker-ce-cli containerd.io \
                   gnupg2 pass jq python3-pip terraform kubectl=${K8S_VERSION}

# Docker user and permissions
echo "[F5GC Cloud Init] Docker user and permissions"
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
echo "[F5GC Cloud Init] Install awscli"
export LC_ALL=C
pip3 install awscli --upgrade

# Install Helm
echo "[F5GC Cloud Init] Install helm"
cd /tmp
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install K9s
echo "[F5GC Cloud Init] Install k9s"
cd /tmp
curl -LO https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz
tar xvfz k9s_Linux_x86_64.tar.gz
mv k9s /usr/local/bin
chmod +x /usr/local/bin/k9s

# Install Istioctl
echo "[F5GC Cloud Init] Install istioctl"
cd /tmp
curl -LO https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz
tar xvfz istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz
mv istioctl /usr/local/bin
chmod +x /usr/local/bin/istioctl

# Indicate completion of bootstrapping
echo "[F5GC Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done
