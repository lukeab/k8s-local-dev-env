# TODO

Manage some priorities of tasks to get done soon:

* [ ] TODO: TODO's in README.md update docs
* [x] TODO: For bootstrap add base domain option other than `*-k3d.localhost` which is hardcoded for now :heavy_check_mark:
* [x] TODO: consider using .env files approach also for tasks :heavy_check_mark:
* [ ] TODO: Enable configuration that can re-point the baseservices path, additional paths or to git repo's to sync in addition to base services, eg personal repository or per application repostiroy for argocd
* [ ] TODO: add opentelemetry SDK to produce metrics to fastapi demo
* [ ] TODO: Figure out if autoinstrumentation can propogate traceid to logs without otel sdk (standard logging in flask or fastapi)
* [ ] TODO: add default monitoring dashboard for traces?
* [ ] TODO: verify or implement field mapping for loki to tempo trace links
* [ ] TODO: add default monitoring dashboard for loki.
* [ ] TODO: verify support for or add service monitor crd for collectors? so as to implement prom metrics for collectors
* [ ] TODO: Look at local oauth IDP (keycloak?) - try to select lightest weight option.
