# Local development k3d cluster with metrics tracing and logging and more

This is a local kubernetes cluster setup using k3d to run them in containers for a very lightweight local development environment. The hope is this can be used for developers to learn kubernetes principles, test service deployments without incurring costs in a cloud provider or having enough local resource to run it all on VM's or external hardware.

Sticking to some principles of choosing tooling that stays local to the environment, not depending on any external services where possible, development should be possible within local developer environments while feeling much like a pre-prod like or production like setup, complete with aggregated logging, metrics, tracing and Gitops. More features to be determined and described later.

## Platform Support

Right now it's only tested on linux (ubuntu 22.04) but hopefully will work on most linux environments, and perhaps windows WSL2. Mac (maybe docker desktop?) support also to be investigated.

## Dependencies

The project is setup using the `Taskfile.yaml` in the root of the project, this uses the [go-task tool](https://taskfile.dev/).

Using the [asdf-vm runtime version manager](https://asdf-vm.com/) to install `go-task` and for `k3d`, `kubectl` and `helm`, and many other cases, is highly recommended. (Or brew on mac if preferred)

Install the dependencies in your OS before beginning, `docker` `openssl` `libnss3-tools` `k3d` `kubectl` `helm`, `jq`.

In Linux, the `libnss3-tools` package delivers the `certutil` allowing you to register certificates for trust by the Chrome browser. (Firefox: unknown, Mac: should be possible, Windows..emm.) Otherwise the cert can be manually added ot your browser trust through the browser security preferences.

TODO: add description on how to reach the ca file to load manually into browsers if needed.

### Recommendations

#### libnss-myhostname

By installing the `libnss-myhostname` package, you can use *.localhost domains, on linux(`Ubuntu`). This can be used to resolve any depth of subdomains prefixed in front of `.localhost` to `127.0.0.1` so you can reference services by hostnames in your local dev environment.

**NOTE**
:exclamation: however golang tools like `argocd` do not default to the libc DNS resolution, so reliability of this is up for testing

#### k8slens.dev

Another useful tool is the [k8slens.dev](https://k8slens.dev/) app which can be used to easily view your local dev environment kubernetes cluster and any other configured kubernetes clusters you may want to visually inspect or operate.

## Bootstrap the cluster

To startup the cluster, customize the .env file, or in your shell, for example optionally export new values for the `LOCAL_DEV_DNS_SUFFIX` or `CLUSTER_NAME` environment variable in your shell, then run the bootstrap task:

```bash
export LOCAL_DEV_DNS_SUFFIX=127.0.0.1.nip.io # optional
task bootstrap
```

This will create a light weight (k3s based) kubernetes cluster in docker containers, including by default the traefik proxy as a load balancer and a docker registry which can be accessed at `registry.<CLUSTER_NAME>.<LOCAL_DEV_DNS_SUFFIX>:5000` from within the cluster and from your workspace as `localhost:5000`, as well as the dns address as within your cluster.

```bash
docker build ./fastapidemo/ -f ./fastapidemo/Dockerfile -t localhost:5000/fastapidemo:v0.1
docker push localhost:5000/fastapidemo:v0.1
```

The `k3d_config.yaml` file shows the cluster configuration specifics.

TODO: document the environment variable driven configurations available, eg. OS_CERT_PATH, K3D_VOLUMES_OVERRIDE, K3D_CONFIG_FILE

## ArgoCD

ArgoCD is installed by default with bootstrap. This will allow deploying components from a local directory using the `argocd` cli tool.

TODO:Other cluster base services, Logging, Metrics tracing and ssl components will be deployed through gitops.

During bootstrap, argocd will automatically login, but to see the ui, got to `https://argocd.<CLUSTER_NAME>.<LOCAL_DEV_DNS_SUFFIX>`

Retreive the password with:

```bash
$> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Removing the CA cert trust

Since you don't want CA's sticking around your computer's trust store, it is deleted when you are done with the environment. If you notice it fails to delete the manual process is below.

```bash
$> rm /usr/local/share/ca-certificates/cert-manager-ca-local.crt
$> sudo update-ca-certificates -f 
## or if on arch or fedora
$> sudo update-ca-trust
```

The `-f` is fresh switch to remove symlinks in case anyting else was done with the cert file.

## Setup workload to produce traces

The `fastpi-demo` folder containers a simple python app to trace and produce metrics (WIP)

Build the container

```bash
cd fastapi-demo
docker build . -t localhost:5000/fastapidemo:v0.1
docker push localhost:5000/fastapidemo:v0.1
kubectl apply -f test_deploy.yaml
```
