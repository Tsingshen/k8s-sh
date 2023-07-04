#!/bin/bash

# 更改为你要创建的用户名称
USER_NAME="vs-ro"
NAMESPACE="default"
SERVER_ADDR="https://xx.com"

# 创建sa
kubectl -n ${NAMESPACE} create sa ${USER_NAME}

# 绑定secret
kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${USER_NAME}
  annotations:
    kubernetes.io/service-account.name: ${USER_NAME}
type: kubernetes.io/service-account-token
EOF
# 创建cluster role,配置正确的权限
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${USER_NAME}
rules:
- apiGroups:
  - networking.istio.io
  resources:
  - virtualservices
  verbs:
  - get
  - list
  - watch
EOF
# 创建cluster rolebinding
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${USER_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${USER_NAME}
subjects:
- kind: ServiceAccount
  name: ${USER_NAME}
  namespace: ${USER_NAME}
EOF
#生成kubeconfig配置文件

secret_data_ca_crt=$(kubectl get secrets ${USER_NAME} -o go-template='{{index .data "ca.crt"}}')
secret_data_token=$(kubectl get secrets ${USER_NAME} -o go-template='{{index .data "token"}}'|base64 -d)

echo """
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${secret_data_ca_crt}
    server: ${SERVER_ADDR}
  name: cluster-${USER_NAME}
contexts:
- context:
    cluster: cluster-${USER_NAME}
    namespace: default
    user: cluster-${USER_NAME}
  name: cluster-${USER_NAME}
current-context: cluster-${USER_NAME}
kind: Config
preferences: {}
users:
- name: cluster-${USER_NAME}
  user:
    token: ${secret_data_token}"""
