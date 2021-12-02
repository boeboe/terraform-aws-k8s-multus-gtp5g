#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} "
  mkdir -p /home/ubuntu/kubernetes
  curl https://docs.projectcalico.org/manifests/calico.yaml -o /home/ubuntu/kubernetes/calico.yaml
  curl https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick-plugin.yml -o /home/ubuntu/kubernetes/multus.yml
  kubectl apply -f /home/ubuntu/kubernetes/calico.yaml
  kubectl apply -f /home/ubuntu/kubernetes/multus.yml
" >/dev/null
