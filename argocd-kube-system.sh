#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "$0 NAME App_Path"
  echo "ex) $0 metrics-server metrics-server"
  exit 0
fi

REPO="https://github.com/gelius7/valve-argotools.git"
DEST_SERVER="https://kubernetes.default.svc"

DEST_NAMESPACE="kube-system"


IS_EXIST=$(argocd repo list | grep ${REPO} | wc -l)
if [[ $IS_EXIST -ne 1 ]]; then
  echo "Add Repository ${REPO}"
  argocd repo add ${REPO}
  argocd proj create ${DEST_NAMESPACE} --src ${REPO} --dest https://kubernetes.default.svc,${DEST_NAMESPACE}
  argocd proj allow-cluster-resource ${DEST_NAMESPACE} "*" "*"

  argocd proj list
fi

IS_EXIST=$(argocd proj list | grep ${DEST_NAMESPACE} | wc -l)

if [[ $IS_EXIST -ne 1 ]]; then
  echo "Create argocd project ${DEST_NAMESPACE}"
  argocd proj create ${DEST_NAMESPACE} --src ${REPO} --dest https://kubernetes.default.svc,${DEST_NAMESPACE}
  argocd proj allow-cluster-resource ${DEST_NAMESPACE} "*" "*"

  argocd proj list
fi

NAME=$1
APP_PATH=${2:-app/$DEST_NAMESPACE/$NAME}

echo "$ argocd app create ${NAME} \
 --repo ${REPO} \
 --path ${APP_PATH} \
 --dest-server ${DEST_SERVER} \
 --dest-namespace ${DEST_NAMESPACE}\
 --project ${DEST_NAMESPACE} \
 --upsert"

argocd app create ${NAME} \
      --repo ${REPO} \
      --path ${APP_PATH} \
      --dest-server ${DEST_SERVER} \
      --dest-namespace ${DEST_NAMESPACE} \
      --project ${DEST_NAMESPACE} \
      --upsert


