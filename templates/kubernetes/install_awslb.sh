#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} '
  kubectl patch nodes master -p "{\"spec\":{\"providerID\":\"aws:///${WORKERS_AZ}/${MASTER_INSTANCE_ID}\"}}"
  index=0
  for worker_instance_id in ${WORKER_INSTANCE_IDS} 
  do 
    kubectl patch nodes worker-$index -p "{\"spec\":{\"providerID\":\"aws:///${WORKERS_AZ}/$worker_instance_id\"}}"
    let "index++"
  done
  helm repo add eks https://aws.github.io/eks-charts
  if helm  -n kube-system status aws-load-balancer-controller > /dev/null 2>&1 ; then
    helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
      --set clusterName=${CLUSTER_NAME} \
      --set image.repository=amazon/aws-alb-ingress-controller \
      --set hostNetwork=true
  else
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
      --set clusterName=${CLUSTER_NAME} \
      --set image.repository=amazon/aws-alb-ingress-controller \
      --set hostNetwork=true
  fi
' >/dev/null
