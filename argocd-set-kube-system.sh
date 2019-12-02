#!/bin/bash

CUR_DIR=${0%/*}
CUR_OBJECT=`echo $CUR_DIR | cut -d "/" -f6`
CUR_NAME=${0##*/}

SHELL_DIR=$(dirname $0)
. ${SHELL_DIR}/common.sh


readonly SHORT_OPT="hn:p:"
readonly LONG_OPT="help,name:,path:"

_help() {
    cat <<EOF
================================================================================
Usage:  $0 -n NAME -p App_Path

Params:
    -h, --help                  현재 화면을 보여줍니다.

    -n, --name                  argocd 로 설치할 application name
    -p, --path                  argocd 로 설치할 application path

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
                PARAM_NAME=${1}
                ;;
            -p|--path)
                shift
                PARAM_PATH=${1}
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

  if [ -z ${PARAM_NAME} ]; then
    _error "Need to Application name"
  fi

  if [ -z ${PARAM_PATH} ]; then 
    _error "Need to Application path in Git repo"
  fi

  _command "argocd repo add ${PARAM_REPO} --username ${PARAM_USER} --password {PASSWORD}"
  argocd repo add ${PARAM_REPO} --username ${PARAM_USER} --password ${PARAM_PW}
  argocd repo list

}

_run $@