#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} '
  kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
  kubectl patch storageclass local-path -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}"
' >/dev/null
