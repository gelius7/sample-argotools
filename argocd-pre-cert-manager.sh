#!/bin/bash

NAMESPACE="kube-ingress"

kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml

kubectl label namespace ${NAMESPACE} certmanager.k8s.io/disable-validation=true

