#!/usr/bin/env bash

kubectl create deployment hello-node-1 --image=k8s.gcr.io/echoserver:1.4
kubectl create deployment hello-node-2 --image=k8s.gcr.io/echoserver:1.4
kubectl create deployment hello-node-3 --image=k8s.gcr.io/echoserver:1.4

kubectl create deployment multitool1 --image=praqma/network-multitool
kubectl create deployment multitool2 --image=praqma/network-multitool
kubectl create deployment multitool3 --image=praqma/network-multitool
