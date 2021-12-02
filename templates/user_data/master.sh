#!/bin/bash

echo "START F5GC Cloud Init"

# Update hostname
echo "[F5GC Cloud Init] Update hostname"
echo master > /etc/hostname
hostnamectl set-hostname master

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

# Run kubeadm to bootstrap master
echo "[F5GC Cloud Init] Run kubeadm to bootstrap master"
kubeadm init \
  --token "${K8S_TOKEN}" \
  --token-ttl 15m \
  --apiserver-cert-extra-sans "${MASTER_PRIVATE_IP}" \
  --pod-network-cidr "${SUBNET_CIDR_POD_NETWORK}" \
  --node-name master

# Prepare kubeconfig file
echo "[F5GC Cloud Init] Prepare kubeconfig file"
mkdir /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
kubectl --kubeconfig /home/ubuntu/.kube/config config set-cluster kubernetes --server https://${MASTER_PRIVATE_IP}:6443

# Wait for kubernetes up
# echo "[F5GC Cloud Init] Wait for kubernetes up"
# while ! kubectl get nodes > /dev/null 2>&1 ; do sleep 1 ; echo -n "." ; done
# echo "[F5GC Cloud Init] UP"

# Install calico cni
# echo "[F5GC Cloud Init] Install calico cni"
# curl https://docs.projectcalico.org/manifests/calico.yaml -o /home/ubuntu/calico.yaml
# kubectl apply -f /home/ubuntu/calico.yaml

# Indicate completion of bootstrapping
echo "[F5GC Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done

# Restart
echo "[F5GC Cloud Init] Restarting host"
init 6
