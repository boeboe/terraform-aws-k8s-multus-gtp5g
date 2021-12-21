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

# Allow IP Forwarding
echo "[Terraform Cloud Init] Allow IP Forwarding"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=2/g' /etc/sysctl.conf

# Update and install aptitude packages
echo "[Terraform Cloud Init] Update and install aptitude packages"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
add-apt-repository -y "deb [arch=amd64] https://apt.kubernetes.io/ kubernetes-xenial main"

apt-get -y update
if [ "${APT_UPGRADE}" = true ] ; then apt-get -y upgrade ; fi
apt-get -y install apt-transport-https ca-certificates software-properties-common \
                   curl net-tools nmap httpie tcpdump wget socat tree locate jq \
                   build-essential make git \
                   docker-ce docker-ce-cli containerd.io \
                   kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION} kubernetes-cni
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
modprobe gtp5g

# Run kubeadm to bootstrap master
echo "[Terraform Cloud Init] Run kubeadm to bootstrap master"
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
private_ip=$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
availability_zone=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone)
mkdir -p /home/ubuntu/kubernetes
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
    - "$private_ip"
    - "${MASTER_PUBLIC_DNS}"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
providerID: "aws:///$availability_zone/$instance_id"
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

mkdir -p /home/ubuntu/kubernetes
chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Install calico cni
if [ "${INSTALL_CALICO_CNI}" = true ] ; then 
  echo "[Terraform Cloud Init] Install calico cni"
  curl ${CALICO_CNI_URL} -o /home/ubuntu/kubernetes/calico.yaml
  kubectl apply -f /home/ubuntu/kubernetes/calico.yaml
fi

# Install aws-vpc cni
if [ "${INSTALL_AWS_VPC_CNI}" = true ] ; then 
  echo "[Terraform Cloud Init] Install aws-vpc cni"
  curl ${AWS_VPC_CNI_URL} -o /home/ubuntu/kubernetes/aws-vpc.yaml
  sed -i 's/us-west-2/eu-west-1/g' /home/ubuntu/kubernetes/aws-vpc.yaml
  kubectl apply -f /home/ubuntu/kubernetes/aws-vpc.yaml
fi

# Install multus cni
if [ "${INSTALL_MULTUS_CNI}" = true ] ; then 
  echo "[Terraform Cloud Init] Install multus cni"
  curl ${MULTUS_CNI_URL} -o /home/ubuntu/kubernetes/multus.yaml
  kubectl apply -f /home/ubuntu/kubernetes/multus.yaml
fi

# Install whereabouts network plugin
if [ "${INSTALL_WHEREABOUTS_PLUGIN}" = true ] ; then 
  echo "[Terraform Cloud Init] Install whereabouts network plugin"
  curl ${WHEREABOUTS_PLUGIN_URL} -o /home/ubuntu/kubernetes/whereabouts.yaml
  kubectl apply -f /home/ubuntu/kubernetes/whereabouts.yaml
fi

# Install rancher local path storage class
if [ "${INSTALL_RANCHER_LOCAL_STORAGE}" = true ] ; then 
  echo "[Terraform Cloud Init] Install rancher local path storage class"
  curl ${RANCHER_LOCAL_STORAGE_URL} -o /home/ubuntu/kubernetes/rancher-storage.yaml
  kubectl apply -f /home/ubuntu/kubernetes/rancher-storage.yaml
  kubectl patch storageclass local-path -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}"
fi

chown -R ubuntu:ubuntu /home/ubuntu/kubernetes

# Indicate completion of bootstrapping
echo "[Terraform Cloud Init] Indicate completion of bootstrapping"
touch /home/ubuntu/done

# Restart
echo "[Terraform Cloud Init] Restarting host"
init 6
