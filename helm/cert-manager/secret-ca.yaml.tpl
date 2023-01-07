apiVersion: v1
kind: Secret
metadata: 
  name: secret-ca-cert-manager
  namespace: cert-manager
type: Opaque
data:
  tls.crt: ${B64_CRT}
  tls.key: ${B64_KEY}