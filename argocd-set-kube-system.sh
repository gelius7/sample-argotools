#!/bin/bash

CUR_DIR=${0%/*}
CUR_OBJECT=`echo $CUR_DIR | cut -d "/" -f6`
CUR_NAME=${0##*/}

SHELL_DIR=$(dirname $0)
. ${SHELL_DIR}/common.sh

LIST=${CUR_DIR}/.${CUR_NAME}-list

NAME=""
APP_PATH=""
REPO="https://github.com/gelius7/sample-argotools.git"
DEST_SERVER="https://kubernetes.default.svc"
DEST_NAMESPACE="kube-system"

readonly SHORT_OPT="hn:p:s:"
readonly LONG_OPT="help,name:,path:,space:"

_help() {
    cat <<EOF
================================================================================
Usage:  $0 -n NAME -p App_Path

Params:
    -h, --help                  현재 화면을 보여줍니다.

    -n, --name                  argocd 로 설치할 application name
    -p, --path                  argocd 로 설치할 application path

    -s, --space                 argocd 로 설치할 application namespace
                                namespace (directory) 안에 있는 모든 application 들을 설치합니다.

================================================================================

EOF
}

_run() {

    OPTIONS=$(getopt -q -l "${LONG_OPT}" -o "${SHORT_OPT}" -a -- "$@" 2>${CUR_DIR}/.tmp)
    if  [ $? -eq 1 ]; then
        _help
        _error "Error params: `cat ${CUR_DIR}/.tmp && rm -f ${CUR_DIR}/.tmp `"
    elif ! [[ $@ =~ '-' ]]; then
        _help
        _error "Error params: $@"
    fi
    eval set -- "${OPTIONS}"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -n|--name)
                shift
                NAME=${1}
                ;;
            -p|--path)
                shift
                APP_PATH=${1}
                ;;
            -s|--space)
                shift
                NAMESPACE_PATH=${1}
                ;;
            -h|--help)
                _help
                exit 0
                ;;
            --)
                # No more options left.
                shift
                break
               ;;
        esac
        shift
    done

    _main

}

__check_argo_repo() {
  IS_EXIST=$(argocd repo list | grep ${REPO} | wc -l)
  if [[ $IS_EXIST -ne 1 ]]; then
    _command "Add Repository ${REPO}"
    argocd repo add ${REPO}
    argocd proj create ${DEST_NAMESPACE} --src ${REPO} --dest https://kubernetes.default.svc,${DEST_NAMESPACE}
    argocd proj allow-cluster-resource ${DEST_NAMESPACE} "*" "*"

    argocd proj list
  fi
}

__check_argo_proj() {
  IS_EXIST=$(argocd proj list | grep ${DEST_NAMESPACE} | wc -l)

  if [[ $IS_EXIST -ne 1 ]]; then
    _command "Create argocd project ${DEST_NAMESPACE}"
    argocd proj create ${DEST_NAMESPACE} --src ${REPO} --dest https://kubernetes.default.svc,${DEST_NAMESPACE}
    argocd proj allow-cluster-resource ${DEST_NAMESPACE} "*" "*"

    argocd proj list
  fi
}

__partial_app() {
  if [ -z ${NAME} ]; then
    _error "Need to Application name"
  fi

  if [ -z ${REPO} ]; then 
    _error "Need to Git repo"
  fi

  if [ -z ${APP_PATH} ]; then 
    _error "Need to APP_PATH"
  fi

  if [ -z ${DEST_SERVER} ]; then 
    _error "Need to DEST_SERVER"
  fi

  if [ -z ${DEST_NAMESPACE} ]; then 
    _error "Need to DEST_NAMESPACE"
  fi

  __check_argo_repo
  __check_argo_proj

  _command "$ argocd app create ${NAME} \
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
}

__directory_app() {

  # list apps
  _command ""
  ls -l ${NAMESPACE_PATH} | grep "^d" | awk '{print $9}' > ${LIST}

  while IFS='' read -r line || [[ -n "$line" ]]; do
    NAME=${line}
    APP_PATH=${NAMESPACE_PATH}/${NAME}
    DEST_NAMESPACE=${NAMESPACE_PATH}
    __partial_app
  done < "${LIST}"

}

_main() {



  if [ -z ${NAMESPACE_PATH} ]; then
    __partial_app
  else
    __directory_app
    
  fi

}

_run $@