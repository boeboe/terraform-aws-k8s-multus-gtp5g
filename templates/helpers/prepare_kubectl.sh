#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
alias scp="scp -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} "
  mkdir -p /home/ubuntu/.kube 
  sshpass -p ubuntu scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${MASTER_PRIVATE_IP}:/home/ubuntu/.kube/config /home/ubuntu/.kube/config
  cp /home/ubuntu/.kube/config /home/ubuntu/kubeconfig-remote.yaml
  sed -i 's/${MASTER_PRIVATE_IP}/${MASTER_PUBLIC_DNS}/g' /home/ubuntu/kubeconfig-remote.yaml
" >/dev/null

scp ubuntu@${BASTION_PUBLIC_IP}:/home/ubuntu/kubeconfig-remote.yaml ${KUBECONFIG_LOCAL}
