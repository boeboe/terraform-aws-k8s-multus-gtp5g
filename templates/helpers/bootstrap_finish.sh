#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

while true; do
  sleep 5
  ! ssh ubuntu@${BASTION_PUBLIC_IP} [[ -f /home/ubuntu/done ]] >/dev/null && continue
  ! ssh -J ubuntu@${BASTION_PUBLIC_IP} ubuntu@${MASTER_PRIVATE_IP} [[ -f /home/ubuntu/done ]] >/dev/null && continue
  for worker_private_ip in ${WORKER_PRIVATE_IPS} ; do
    ! ssh -J ubuntu@${BASTION_PUBLIC_IP} ubuntu@$worker_private_ip [[ -f /home/ubuntu/done ]] >/dev/null && continue
  done
  break
done
