#!/bin/bash

# 更改为你要创建的用户名称
USER_NAME="vs-ro" ## 注意不要使用 cluster-admin 和已经存在的用户, 会冲突
NAMESPACE="default"
CLUSTER_NAME="k8s-test"
SERVER_ADDR="https://xx.com"


# 创建sa
kubectl -n ${NAMESPACE} create sa ${USER_NAME}

# 绑定secret
kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${USER_NAME}
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${USER_NAME}
type: kubernetes.io/service-account-token
EOF
# 创建cluster role,配置正确的权限
kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${USER_NAME}-kube-sh
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
  name: ${USER_NAME}-kube-sh
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${USER_NAME}-kube-sh
subjects:
- kind: ServiceAccount
  name: ${USER_NAME}
  namespace: ${NAMESPACE}
EOF
#生成kubeconfig配置文件

echo  "wait for k8s generate resource for 5 seconds ..."
sleep 5
secret_data_ca_crt=$(kubectl -n ${NAMESPACE} get secrets ${USER_NAME} -o go-template='{{index .data "ca.crt"}}')
secret_data_token=$(kubectl -n ${NAMESPACE} get secrets ${USER_NAME} -o go-template='{{index .data "token"}}'|base64 -d)

echo """生成的kueconfig为:
---
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${secret_data_ca_crt}
    server: ${SERVER_ADDR}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: default
    user: ${CLUSTER_NAME}-${USER_NAME}
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
- name: ${CLUSTER_NAME}-${USER_NAME}
  user:
    token: ${secret_data_token}"""
