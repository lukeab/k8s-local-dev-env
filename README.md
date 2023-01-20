# Local development k3d cluster with metrics tracing and logging and more

This is a local kubernetes cluster setup using k3d to run them in containers for a very lightweight local development environment. The hope is this can be used for developers to learn kubernetes principles, test service deployments without incurring costs in a cloud provider or having enough local resource to run it all on VM's or external hardware.

Sticking to some principles of choosing tooling that stays local to the environment, not depending on any external services where possible, development should be possible within local developer environments while feeling much like a pre-prod like or production like setup, complete with aggregated logging, metrics, tracing and Gitops. More features to be determined and described later.

## Platform Support

Right now it's only tested on linux (ubuntu 22.04) but hopefully will work on most linux environments, and perhaps windows WSL2. Mac (maybe docker desktop?) support also to be investigated.

## Dependencies

The project is setup using the `Taskfile.yaml` in the root of the project, this uses the [go-task tool](https://taskfile.dev/). 

Using the [asdf-vm runtime version manager](https://asdf-vm.com/) to install `go-task` and for `k3d`, `kubectl` and `helm`, and many other cases, is highly recommended. (Or brew on mac if preferred)

Install the dependencies in your OS before beginning, `docker` `openssl` `libnss3-tools` `k3d` `kubectl` `helm`.

In Linux, the `libnss3-tools` package delivers the `certutil` allowing you to register certificates for trust by the Chrome browser. (Firefox: unknown, Mac: should be possible, Windows..emm.) Otherwise the cert can be manually added ot your browser trust through the browser security preferences.

TODO: add description on how to reach the ca file to load manually into browsers if needed.

### Recommendations

By installing the `libnss-myhostname` package, you can use *.localhost domains, on linux(`Ubuntu`).  This will resolve any depth of subdomains prefixed in front of `.localhost` to `127.0.0.1` so you can reference services by hostnames in your local dev environment.

Another useful tool is the [k8slens.dev](https://k8slens.dev/) app which can be used to easily view your local dev environment kubernetes cluster and any other configured kubernetes clusters you may want to visually inspect or operate.

## Bootstrap the cluster

```bash
task bootstrap
```

This creates a light weight (k3s based) kubernetes cluster in docker containers, including by default the traefik proxy as a load balancer and a docker registry which can be accessed at `registry.localhost:5000` from within the cluster and additionaly both urls adding `localhost:5000` as another available address.

The `k3d_config.yaml` file shows the cluster configuration specifics.

TODO: document the environment variable driven configurations available, eg. OS_CERT_PATH, K3D_VOLUMES_OVERRIDE, K3D_CONFIG_FILE


## ArgoCD

ArgoCD is installed by default with bootstrap. This will allow deploying components from a local directory using the `argocd` cli tool. 

TODO:Other cluster base services, Logging, Metrics tracing and ssl components will be deployed through gitops.

During bootstrap, argocd will automatically login, but for the weui, got to https://argocd.k3d.localhost
Retreive the password with:

```bash
$> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Setup cert-manager

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> helm repo add jetstack https://charts.jetstack.io
$> helm repo update
$> helm upgrade -i -n cert-manager --create-namespace cert-manager jetstack/cert-manager -f helm/cert-manager/values.yaml
```

### Install CA Cluster Issuer

**NOTE**
:exclamation: To be deprecated with argocd setup

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

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n prometheus --create-namespace prom-operator prometheus-community/kube-prometheus-stack -f helm/prometheus/values.yaml
```

## Setup loki

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> helm repo add grafana https://grafana.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n loki --create-namespace loki-stack grafana/loki-stack -f helm/loki-stack/values.yaml
```

## Setup Grafana Tempo

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> helm repo add grafana https://grafana.github.io/helm-charts
$> helm repo update
$> helm upgrade -i -n tempo --create-namespace tempo grafana/tempo -f helm/tempo/values.yaml
```

## Setup OTel operator

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$> helm repo update
$> helm upgrade -i -n otel-operator --create-namespace otel-operator open-telemetry/opentelemetry-operator -f helm/otelcollector/values.yaml
```

### Install a OTel Collector service

**NOTE**
:exclamation: To be deprecated with argocd setup

```bash
$> kubectl apply -f helm/otelcollector/collector.yaml
$> kubectl apply -f helm/otelcollector/Instrumentation.yaml
```

## Setup workload to produce traces

The `fastpi-demo` folder containers a simple python app to trace and produce metrics (WIP)

Build the container

```bash
cd fastapi-demo
docker build . -t localhost:5000/fastapidemo:v0.1
docker push localhost:5000/fastapidemo:v0.1
kubectl apply -f test_deploy.yaml
```



