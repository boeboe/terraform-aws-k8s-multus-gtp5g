#!/bin/bash

echo "START F5GC Cloud Init"

# Update hostname
echo "[F5GC Cloud Init] Update hostname"
echo worker-${WORKER_INDEX} > /etc/hostname
hostnamectl set-hostname worker-${WORKER_INDEX}

# Update passwords
echo "[F5GC Cloud Init] Update passwords"
echo -e "ubuntu\nubuntu" | passwd ubuntu
echo -e "root\nroot" | passwd root

# Allow SSH access with user/pass
echo "[F5GC Cloud Init] Allow SSH access with user/pass"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Update and install aptitude packages
echo "[F5GC Cloud Init] Update and install aptitude packages"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
add-apt-repository -y "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"

apt-get -y update ; apt-get -y upgrade
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat tree locate \
                   build-essential make git \
                   docker-ce docker-ce-cli containerd.io \
                   kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
apt-mark -y hold kubelet kubeadm kubectl

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

# Install gtp5g kernel module
echo "[F5GC Cloud Init] Install gtp5g kernel module"
cd /tmp
git clone https://github.com/free5gc/gtp5g.git
cd gtp5g
sed -i 's/ip_tunnel_get_stats64/dev_get_tstats64/g' gtp5g.c
make clean && make && make install

# Run kubeadm to bootstrap worker
echo "[F5GC Cloud Init] Run kubeadm to bootstrap worker"
kubeadm join ${MASTER_PRIVATE_IP}:6443 \
  --token ${K8S_TOKEN} \
  --discovery-token-unsafe-skip-ca-verification \
  --node-name worker-${WORKER_INDEX}

# Indicate completion of bootstrapping
echo "[F5GC Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done

# Restart
echo "[F5GC Cloud Init] Restarting host"
init 6
