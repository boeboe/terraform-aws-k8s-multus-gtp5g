#!/bin/bash

echo "START Terraform Cloud Init"

# Update hostname
echo "[Terraform Cloud Init] Update hostname"
echo worker-${WORKER_INDEX} > /etc/hostname
hostnamectl set-hostname worker-${WORKER_INDEX}

# Update passwords
echo "[Terraform Cloud Init] Update passwords"
echo -e "ubuntu\nubuntu" | passwd ubuntu
echo -e "root\nroot" | passwd root

# Allow SSH access with user/pass
echo "[Terraform Cloud Init] Allow SSH access with user/pass"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Update and install aptitude packages
echo "[Terraform Cloud Init] Update and install aptitude packages"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
add-apt-repository -y "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"

apt-get -y update
if [ "${APT_UPGRADE}" = true ] ; then apt-get -y upgrade ; fi
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat tree locate \
                   build-essential make git \
                   docker-ce docker-ce-cli containerd.io \
                   kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION} kubernetes-cni
apt-mark -y hold kubelet kubeadm kubectl

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

# Install gtp5g kernel module
echo "[Terraform Cloud Init] Install gtp5g kernel module"
cd /tmp
git clone https://github.com/free5gc/gtp5g.git
cd gtp5g
sed -i 's/ip_tunnel_get_stats64/dev_get_tstats64/g' gtp5g.c
make clean && make && make install
modprobe gtp5g

# Run kubeadm to bootstrap worker
echo "[Terraform Cloud Init] Run kubeadm to bootstrap worker"
mkdir -p /home/ubuntu/kubernetes
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
cat <<EOF | tee /home/ubuntu/kubernetes/kubeadm-worker.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken: 
    apiServerEndpoint: ${MASTER_PRIVATE_IP}:6443
    token: "${K8S_TOKEN}"
    unsafeSkipCAVerification: true
nodeRegistration:
  name: "worker-${WORKER_INDEX}"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
providerID: "aws:///${AVAILABILITY_ZONE}/$instance_id"
EOF
kubeadm join --config /home/ubuntu/kubernetes/kubeadm-worker.yaml
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Indicate completion of bootstrapping
echo "[Terraform Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done

# Restart
echo "[Terraform Cloud Init] Restarting host"
init 6
