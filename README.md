# Local development k3d cluster with metrics tracing and logging and more

This is a local kubernetes cluster setup using [k3d](https://k3d.io), [ArgoCD](https://argoproj.github.io/cd), [Prometheus](https://prometheus.io/), [Loki](https://grafana.com/oss/loki/), [Tempo](https://grafana.com/oss/tempo/) and [OpenTelemetry](https://opentelemetry.io/) for a very lightweight local development environment with full Observability (Logging, Metrics and Tracing). Additionally [cert-manager](https://cert-manager.io/) is deployed along with a CA which is setup to be trusted by your OS and Chrome by the bootstrap process, to smoothly offer fully working SSL(TLS) certificate secured pages for your local development enjoyment.

The idea is this can be used for developers to learn kubernetes principles, test service deployments without incurring costs in a cloud provider or having enough local resource to run it all on without using VM's or external hardware.

One goal of the project is to to try adhere to a local resources principle: choosing tooling that stays local to the environment, not depending on any external services where possible. This is to allow development to be possible within local developer environments while feeling much like a pre-prod like or production like setup, complete with aggregated logging, metrics, tracing and Gitops. More features to be determined and described later.

## Platform Support

Right now it's only tested on linux (ubuntu 22.04 / Archlinux) but hopefully will work on most linux environments. In future perhaps windows WSL2, Mac (maybe docker desktop?) support also to be investigated.

## Dependencies

The project is setup using the `Taskfile.yaml` in the root of the project, this uses the [go-task tool](https://taskfile.dev/).

Using the [asdf-vm runtime version manager](https://asdf-vm.com/) to install `go-task` and for `k3d`, `kubectl` and `helm`, and many other tools, is highly recommended to use. Or brew on mac if preferred(to be tested). A `.tool-versions` file is provided to help onboard with asdf, providing tool versions of the dependencies where possible.

Install the non asdf dependencies in your OS before beginning, `docker` `openssl`. If not using asdf, alternate source (system package manager, other dependency tool) can provide the other tools, see the [`.tool-versions`](./.tool-versions) file for a list of requirements and optional tools.

In Ubuntu, the `libnss3-tools` package delivers the `certutil` command, allowing you to register certificates for trust by the Chrome browser. (Firefox: unknown, Mac: should be possible, Windows..emm.) Otherwise the cert can be manually added ot your browser trust through the browser security preferences.

TODO: add description on how to reach the ca file to load manually into browsers if needed.

### Recommendations

#### k8slens.dev

Another useful tool is the [k8slens.dev](https://k8slens.dev/) app which can be used to easily view your local dev environment kubernetes cluster and any other configured kubernetes clusters you may want to visually inspect or operate.

#### kubectx/kubens

Command line tools `kubectx` and `kubens` are plugins for easily switching kubernetes cluster and current active namespaces in your `~/.kube/config` file. Generally just a good idea. It is included in the `asdf` [`.tool-versions`](./.tool-versions) file, but otherwise see the github page [ahmetb/kubectx](https://github.com/ahmetb/kubectx#installation) for approaches to install it.

#### libnss-myhostname

By installing the `libnss-myhostname` package, you can use *.localhost domains, on linux(`Ubuntu`). This can be used to resolve any depth of subdomains prefixed in front of `.localhost` to `127.0.0.1` so you can reference services by hostnames in your local dev environment.

If you choose to do this, update the `.env` file with the desired `LOCAL_DEV_DNS_SUFFIX`.

**NOTE**
:exclamation: however golang tools like `argocd` do not default to the libc DNS resolution nsswitch mechanism, which uses the /etc/nsswitch.conf preferences, so reliability of this is up for testing.

## Bootstrap the cluster

To startup the cluster, customize the .env file, or in your shell, for example optionally export new values for the `LOCAL_DEV_DNS_SUFFIX` or `CLUSTER_NAME` environment variable in your shell, then run the bootstrap task:

```bash
export LOCAL_DEV_DNS_SUFFIX=127.0.0.1.nip.io CLUSTER_NAME=mydevcluster # optional, example of using nip instead of the default local.gd domain suffix
task bootstrap
```

This will create a light weight (k3s based) kubernetes cluster in docker containers, including by default the [traefik](https://traefik.io/) proxy as a load balancer and a [docker registry](https://docs.docker.com/registry/) which can be accessed at `registry.<CLUSTER_NAME>.<LOCAL_DEV_DNS_SUFFIX>:5000` from within the cluster and from your workspace as `localhost:5000`, as well as the same dns address as within your cluster.

### example use of the registry

```bash
docker build ./fastapidemo/ -f ./fastapidemo/Dockerfile -t localhost:5000/fastapidemo:v0.1
docker push localhost:5000/fastapidemo:v0.1
```

## ArgoCD

ArgoCD, along with the other base services(which are managed in ArgoCD) are installed by default with bootstrap. This can allow deploying components from a local directory using the `argocd` cli tool.

TODO: Document example of deploying local project with argo or other options eg. Tekton, Tilt, Skaffold, gitlab local runner or other options.

During bootstrap, the argocd cli will automatically login, so argocd commands can be run on the conole. But to use the web ui, got to `https://argocd.<CLUSTER_NAME>.<LOCAL_DEV_DNS_SUFFIX>`.

Ther username is defaulted to admin, and retreive the password with:

```bash
$> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Removing the CA cert trust

Since you don't want CA's sticking around your computer's trust store, it is deleted when you `task teardown` and are done with the environment. If you notice it fails to delete the manual process is below.

```bash
$> rm <OS_CERT_PATH>/k8s-<CLUSTER_NAME>-cert-manager-ca.crt
$> sudo update-ca-certificates -f 
## or if on arch or fedora
$> sudo update-ca-trust
```

The OS_CERT_PATH depends on the distribution of linux. For Mac and Windows cert management proceedures, and a general guide in linux versions, refer to [manuals.gfi.com adding-trust-root-certificates](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)

Google Chrome uses `certutil` from `libnss3-tools` package to manage the certificiate trust database. You can check what certificates are registered by running

```bash
$> certutil -L -d sql:$HOME/.pki/nssdb
```

If you see the local development CA in the list, you can manually remove it with:

```bash
$> 
```

## Setup workload to produce traces

The `fastpi-demo` folder containers a simple python app to trace and produce metrics (still a WIP)

Build the container

```bash
cd fastapi-demo
docker build . -t localhost:5000/fastapidemo:v0.1
docker push localhost:5000/fastapidemo:v0.1
kubectl apply -f test_deploy.yaml
```

TODO: add a task to taskfile.yaml to bundle this
