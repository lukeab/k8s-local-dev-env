#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

#gen a ca signing cert
if [ ! -f ca.key ]; then
  openssl genrsa -out "${SCRIPT_DIR}/ca.key" 4096
fi

if [ ! -f ca.key ]; then 
  openssl req -new -x509 -sha256 --config "${SCRIPT_DIR}/config.cnf" -days 10950 -key "${SCRIPT_DIR}/ca.key" -out "${SCRIPT_DIR}/ca.cert"
fi

B64_CRT="$(base64 -w 0 ca.crt)"
B64_KEY="$(base64 -w 0 ca.key)"
export B64_CRT B64_KEY

#put into secret-ca.yaml
envsubst < "${SCRIPT_DIR}/secrets-ca.yaml.tpl" > "${SCRIPT_DIR}/secret.ca.yaml"

kubectl apply --namespace cert-manager -f "${SCRIPT_DIR}/secret-ca.yaml"

#echo "${B64_CRT}" > "${SCRIPT_DIR}/cert-manager-ca-local.crt"
sudo cp "${SCRIPT_DIR}/ca.crt" /usr/local/share/ca-certificates/

sudo update-ca-certificates

## steps for removing this cert
# rm /usr/local/share/ca-certificates/cert-manager-ca-local.crt
# sudo update-ca-certificates -f # -f is fresh switch to remove symlinks


