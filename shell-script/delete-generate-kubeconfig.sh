#!/bin/bash

USER_NAME="vs-ro"
NAMESPACE="default"

kubectl -n ${NAMESPACE} delete sa
kubectl -n ${NAMESPACE} delete clusterrole,clusterrolebindings ${USER_NAME}-kube-sh
 
