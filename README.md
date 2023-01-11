# Local development k3d cluster with metrics tracing and logging

## Dependencies

Install the dependencies before beginning

`docker` `openssl` `libnss3-tools` `k3d` `kubectl` `helm`

The `libnss3-tools` package delivers the `certutil` allowing you to register certificates for trust by chrome.

### Recommendations

For `k3d`, `kubectl` and `helm`, it is highly recommended to use the asdf-vm version manager. [asdf-vm](https://asdf-vm.com/)

So you can use *.localhost domains, on linux(`Ubuntu`) install `libnss-myhostname` package, this will resolve any depth of subdomains prefixed in front of `.localhost` to `127.0.0.1` so you can reference services by hostnames in your local dev environment.

Another useful tool is the [k8slens.dev](https://k8slens.dev/) app which can be used to easily view your local dev environment and any other configured kubernetes clusters.

## Setup the Cluster

```bash
k3d cluster create --config k3d_config.yaml
```

This creates a light weight (k3s based) kubernetes cluster in docker containers, including by default the traefik proxy as a load balancer and a docker registry which can be accessed at `registry.localhost:5000` from within the cluster and additionaly both urls adding `localhost:5000` as another available address.

## Setup ArgoCD

Setting this up will allow deploying components from a local directory using the `argocd` cli tool. There will be follow on components that will allow ssl connectivity, it is to be determined if the local CA can be managed through gtitops.

```bash
$> helm repo add argo https://argoproj.github.io/argo-helm
$> helm repo update
$> helm upgrade -i -n argocd --create-namespace argocd argo/argo-cd -f helm/argocd/values.yaml
```

Retreive the password with:

```bash
$> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Setup cert-manager

```bash
$> helm repo add jetstack https://charts.jetstack.io
$> helm repo update
$> helm upgrade -i -n cert-manager --create-namespace cert-manager jetstack/cert-manager -f helm/cert-manager/values.yaml
```

### Install CA Cluster Issuer

A setup script has been prepared which will generate and trust locally a key and CA certificate.

```bash
$> ./helm/cert-manager/setup_local_dev_ca.sh
```

This will be loaded into the k3d cluster as the keys to a self signed CA Cluster Issuer `ca-local-dev`. The cert will also be added to your linux system trust `/usr/local/share/ca-certificates/cert-manager-ca-local.crt`.

In future, for windows of Mac platforms this could be made cross platform.

### Removing this cert

Since you don't want CA's sticking around your computer's trust store, delete it when you are done with the environment.

```bash
$> rm /usr/local/share/ca-certificates/cert-manager-ca-local.crt
$> sudo update-ca-certificates -f 
```

The `-f` is fresh switch to remove symlinks in case anyting else was done with the cert file.

## Setup prometheus-stack

```bash
$> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n prometheus --create-namespace prom-operator prometheus-community/kube-prometheus-stack -f helm/prometheus/values.yaml
```

## Setup loki

```bash
$> helm repo add grafana https://grafana.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n loki --create-namespace loki-stack grafana/loki-stack -f helm/loki-stack/values.yaml
```

## Setup Grafana Tempo

```bash
$> helm repo add grafana https://grafana.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n tempo --create-namespace tempo grafana/tempo -f helm/tempo/values.yaml
```

## Setup OTel operator

```bash
$> helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$> helm repo update
$> helm upgrade -i -n otel-operator --create-namespace otel-operator open-telemetry/opentelemetry-operator -f helm/otelcollector/values.yaml
```

### Install a OTel Collector service

```bash
$> kubectl apply -f helm/otelcollector/collector.yaml
$> kubectl apply -f helm/otelcollector/Instrumentation.yaml
```

## Setup workload to produce traces

The `fastpi-demo` folder containers a simple python app to trace and produce metrics (WIP)

Build the container

```bash
docker build 
```

TODO:

* add SDK to produce metrics to fastapi demo
* update grafana to view traces from tempo
* add default monitoring dashboard for traces?
* complete loki deployment
* configure grafana to query loki
* add default monitoring dashboard for loki.
* verify existance or add service monitor crd for collectors?
