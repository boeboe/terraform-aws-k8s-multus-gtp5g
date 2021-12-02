#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} "
  mkdir -p /home/ubuntu/.kube 
  sshpass -p ubuntu scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${MASTER_PRIVATE_IP}:/home/ubuntu/.kube/config /home/ubuntu/.kube/config
" >/dev/null
