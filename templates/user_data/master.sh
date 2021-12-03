#!/bin/bash

echo "START Terraform Cloud Init"

# Update hostname
echo "[Terraform Cloud Init] Update hostname"
echo master > /etc/hostname
hostnamectl set-hostname master

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

apt-get -y update ; apt-get -y upgrade
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat tree locate \
                   build-essential make git \
                   docker-ce docker-ce-cli containerd.io \
                   kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
apt-mark -y hold kubelet kubeadm kubectl

# Docker user and permissions
echo "[Terraform Cloud Init] Docker user and permissions"
groupadd docker
usermod -aG docker ubuntu
mkdir /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
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

# Run kubeadm to bootstrap master
echo "[Terraform Cloud Init] Run kubeadm to bootstrap master"
mkdir -p /home/ubuntu/kubernetes
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
cat <<EOF | tee /home/ubuntu/kubernetes/kubeadm-master.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
  - token: "${K8S_TOKEN}"
    description: "kubeadm bootstrap token"
    ttl: "24h"
nodeRegistration:
  name: "master"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: "${SUBNET_CIDR_POD_NETWORK}"
apiServer:
  certSANs:
    - "${MASTER_PRIVATE_IP}"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
providerID: "aws:///${AVAILABILITY_ZONE}/$instance_id"
EOF
kubeadm init --config /home/ubuntu/kubernetes/kubeadm-master.yaml
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Prepare kubeconfig file
echo "[Terraform Cloud Init] Prepare kubeconfig file"
mkdir -p /home/ubuntu/.kube /root/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
cp /etc/kubernetes/admin.conf /root/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
export KUBECONFIG=/root/.kube/config
kubectl config use-context kubernetes-admin@kubernetes

# Wait for kubernetes up
echo "[Terraform Cloud Init] Wait for kubernetes up"
while ! kubectl get nodes > /dev/null 2>&1 ; do sleep 1 ; echo -n "." ; done
echo "[Terraform Cloud Init] UP"

# Install calico cni
echo "[Terraform Cloud Init] Install calico cni"
mkdir -p /home/ubuntu/kubernetes
curl https://docs.projectcalico.org/manifests/calico.yaml -o /home/ubuntu/kubernetes/calico.yaml
kubectl apply -f /home/ubuntu/kubernetes/calico.yaml
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Install multus cni
echo "[Terraform Cloud Init] Install multus cni"
mkdir -p /home/ubuntu/kubernetes
curl https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick-plugin.yml -o /home/ubuntu/kubernetes/multus.yaml
kubectl apply -f /home/ubuntu/kubernetes/multus.yaml
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Install rancher local path storage class
echo "[Terraform Cloud Init] Install rancher local path storage class"
mkdir -p /home/ubuntu/kubernetes
curl https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml -o /home/ubuntu/kubernetes/rancher-storage.yaml
kubectl apply -f /home/ubuntu/kubernetes/rancher-storage.yaml
kubectl patch storageclass local-path -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}"
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Install aws load balancer controller
echo "[Terraform Cloud Init] Install aws load balancer controller"
mkdir -p /home/ubuntu/kubernetes
curl -L https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml -o /home/ubuntu/kubernetes/cert-manager.yaml
curl https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/v2_2_4_full.yaml -o /home/ubuntu/kubernetes/aws-lb-controller.yaml
sed -i 's/your-cluster-name/${CLUSTER_NAME}/g' /home/ubuntu/kubernetes/aws-lb-controller.yaml
kubectl apply --validate=false -f /home/ubuntu/kubernetes/cert-manager.yaml
kubectl apply -f /home/ubuntu/kubernetes/aws-lb-controller.yaml
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Indicate completion of bootstrapping
echo "[Terraform Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done

# Restart
echo "[Terraform Cloud Init] Restarting host"
init 6
