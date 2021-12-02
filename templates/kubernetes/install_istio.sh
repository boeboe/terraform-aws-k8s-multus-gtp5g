#!/bin/bash

alias ssh="ssh -q -i ${PRIVATE_KEY_FILE} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

ssh ubuntu@${BASTION_PUBLIC_IP} '
istioctl operator init
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  components: 
    egressGateways: 
    - name: istio-egressgateway
      enabled: true
    ingressGateways: 
    - name: istio-ingressgateway
      enabled: true
      k8s:
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
          service.beta.kubernetes.io/aws-load-balancer-name: istio-ingressgateway
          service.beta.kubernetes.io/aws-load-balancer-type: external
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
        service:
          type: LoadBalancer
EOF
' >/dev/null
