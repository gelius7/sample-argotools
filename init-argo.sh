#!/bin/bash

CUR_DIR=${0%/*}
CUR_OBJECT=`echo $CUR_DIR | cut -d "/" -f6`
CUR_NAME=${0##*/}

SHELL_DIR=$(dirname $0)
. ${SHELL_DIR}/common.sh


readonly SHORT_OPT="h:p:c:n:"
readonly LONG_OPT="help,host:,newpw:,currentpw:,namespace:"

_help() {
    cat <<EOF
================================================================================
Usage: $0 -h ARGO_HOST -p New_Password  -n Namespace -c Current_Password

Params:
    --help                      현재 화면을 보여줍니다.

    -h, --host                  접근 주소 URL 을 입력합니다.
    -p, --newpw                 새로 설정할 New_Password
                                Default : admin
    -c, --currentpw             현재 설정된 Current_Password
                                Default : argocd init pw
    -n, --namespace             argocd 가 설치된 Namespace, 초기 비밀번호를 가져오기 위해 사용합니다.
                                Current_Password 를 알고 있다면 사용하지 마십시오.
                                Default : devops

================================================================================

ex) $0 -h argo-devops.mysite.com -p newpw -n devops
ex) $0 -h argo-devops.mysite.com -p newpw -c argocd-server-5234134xx-xxxxxx
    
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
            -h|--host)
                shift
                PARAM_HOST=$1
                ;;
            -p|--newpw)
                shift
                PARAM_NEWPW=${1}
                ;;
            -c|--currentpw)
                shift
                PARAM_PW=${1}
                ;;
            -n|--namespace)
                shift
                PARAM_NAMESPACE=${1}
                ;;
            --help)
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

_main() {

  if [ -z ${PARAM_HOST} ]; then
    _error "Need to Argocd URL"
  fi

  if [ -z ${PARAM_NAMESPACE} ]; then 
    PARAM_NAMESPACE="devops"
  fi

  if [ -z ${PARAM_PW} ]; then
    DEFAULT_PW=$(kubectl get pods -n ${PARAM_NAMESPACE} -l app.kubernetes.io/name=argo-cd-server -o name | cut -d'/' -f 2)
    PARAM_PW=${1:-${DEFAULT_PW}}
  fi

  if [ -z ${PARAM_NEWPW} ]; then
    PARAM_NEWPW="admin"
  fi

  _command "echo \"admin\" | argocd login ${PARAM_HOST} --password {CUR_PASSWORD} --grpc-web"
  echo "admin" | argocd login ${PARAM_HOST} --password ${PARAM_PW} --grpc-web

  _command "argocd account update-password --current-password {CUR_PASSWORD} --new-password {PASSWORD}"
  argocd account update-password --current-password ${PARAM_PW} --new-password ${PARAM_NEWPW}
}

_run $@