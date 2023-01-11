#!/bin/bash

set -eo pipefail
[ -n "$DEBUG" ] && set -x

OS_CERT_PATH="/usr/local/share/ca-certificates/cert-manager-localdev-ca.crt"

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

echo "##!! Setting up ca certificate for local development and registering it in your current development cluster context"
echo 
echo "##!! WARNING: This will install a CA certificate in ${OS_CERT_PATH} and update your certificates trust in your operating system and chrome/chromium!"
echo 

#gen a ca signing cert
if [ ! -f "${SCRIPT_DIR}/ca.key" ]; then
  openssl genrsa -out "${SCRIPT_DIR}/ca.key" 4096
fi

if [ ! -f "${SCRIPT_DIR}/ca.crt" ]; then 
  openssl req -new -x509 -sha256 --config "${SCRIPT_DIR}/config.cnf" -days 10950 -key "${SCRIPT_DIR}/ca.key" -out "${SCRIPT_DIR}/ca.crt"
  
fi

B64_KEY="$(base64 -w 0 "${SCRIPT_DIR}/ca.key")"
B64_CRT="$(base64 -w 0 "${SCRIPT_DIR}/ca.crt")"
export B64_KEY B64_CRT
#put into secret-ca.yaml
envsubst < "${SCRIPT_DIR}/secret-ca.yaml.tpl" > "${SCRIPT_DIR}/secret-ca.yaml"

kubectl apply --namespace cert-manager -f "${SCRIPT_DIR}/secret-ca.yaml"
kubectl apply --namespace cert-manager -f "${SCRIPT_DIR}/ClusterIssuer-dev-ca.yaml"

if [ ! -f "${OS_CERT_PATH}" ]; then
  sudo cp "${SCRIPT_DIR}/ca.crt" "${OS_CERT_PATH}"

  sudo update-ca-certificates -f
else 
    echo "${OS_CERT_PATH} already setup - skipping cp and update-ca-certificates"
fi

## steps for removing this cert
# sudo rm /usr/local/share/ca-certificates/cert-manager-localdev-ca.crt
# sudo update-ca-certificates -f # -f is fresh switch to remove symlinks


## Trust cert in chrome/chromium
certutil -d sql:$HOME/.pki/nssdb -A -t "CT,c,c" -n cert-manager-local-dev-ca -i "${SCRIPT_DIR}/ca.crt"
## and remove it
# certutil -d sql:$HOME/.pki/nssdb -D -n cert-manager-local-dev-ca
##list certs
# certutil -L -d sql:$HOME/.pki/nssdb
## show details of certs
# certutil -d sql:$HOME/.pki/nssdb -L -n cert-manager-local-dev-ca

