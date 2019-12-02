#!/bin/bash

CUR_DIR=${0%/*}
CUR_OBJECT=`echo $CUR_DIR | cut -d "/" -f6`
CUR_NAME=${0##*/}

SHELL_DIR=$(dirname $0)
. ${SHELL_DIR}/common.sh


readonly SHORT_OPT="hr:u:p:"
readonly LONG_OPT="help,repo:,user:,passwd:"

_help() {
    cat <<EOF
================================================================================
Usage:  $0 -r https://github.com/my/argo-apps.git -u myname -p mypassword

Params:
    -h, --help                  현재 화면을 보여줍니다.

    -r, --repo                  argocd 에 추가할 repository 주소를 입력합니다.
    -u, --user                  repository 에 접근하기 위한 user
    -p, --passwd                repository 에 접근하기 위한 password

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
            -r|--repo)
                shift
                PARAM_REPO=${1}
                ;;
            -u|--user)
                shift
                PARAM_USER=${1}
                ;;
            -p|--passwd)
                shift
                PARAM_PW=${1}
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

_main() {

  if [ -z ${PARAM_REPO} ]; then
    _error "Need to git URL"
  fi

  if [ -z ${PARAM_USER} ]; then 
    _error "Need to username for git URL"
  fi

  if [ -z ${PARAM_PW} ]; then
    _warn "Need to password for username"
    password
    PARAM_PW=${ANSWER}
  fi

  _command "argocd repo add ${PARAM_REPO} --username ${PARAM_USER} --password {PASSWORD}"
  argocd repo add ${PARAM_REPO} --username ${PARAM_USER} --password ${PARAM_PW}
  argocd repo list

}

_run $@