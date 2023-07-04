#!/bin/bash

USER_NAME="vs-ro"
NAMESPACE="default"

kubectl -n ${NAMESPACE} delete sa,clusterrole,clusterrolebindings ${USER_NAME}
