# apws-opentofu

OpenTofu setup for Docker services (OpenSearch, OpenSearch Dashboards, Logstash, Web, DHT
sensor, Hygrometer) plus a host-level systemd service (camera stream) on a Docker host
reachable via SSH (e.g. a Raspberry Pi). The `docker` provider connects over
`ssh://<ssh_user>@<ssh_host>:22`, so no open Docker port is needed — only SSH.

`logstash`, `web`, `dht`, and `hygrometer` are no longer built from local files, but from
their own GitHub repositories (`apws-logstash`, `apws-web`, `apws-dht`, `apws-hygrometer`) —
see [Git-based image builds](#git-based-image-builds).

See [`docs/deployment.puml`](docs/deployment.puml) for a UML deployment diagram of the
whole setup (hosts, containers, network, volume, and the systemd camera service).

## Prerequisites

- OpenTofu installed
- SSH public-key access to the target host, `ssh_user` must be in the `docker` group there
- `ssh_user` needs **passwordless sudo** on the target host — `modules/systemd_service`
  installs/enables the `rpicam-vid` unit via `sudo systemctl`/`sudo mv` over the same SSH
  connection, with no separate password prompt available
- On the target host, once, for OpenSearch:
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  # permanently: add to /etc/sysctl.conf
  ```
- `git` installed locally (needed for the image builds, see below)
- Target host is a Raspberry Pi with GPIO (`/dev/gpiochip0`, used by `web` and `dht`), I2C
  (`/dev/i2c-1`, used by `hygrometer`), and a camera (`rpicam-vid`, used by the systemd
  service below) — `docker_platform` defaults to `linux/arm64/v8` accordingly

## Configuration

```hcl
ssh_host                 = "192.168.8.168"
ssh_user                 = "pi"
opensearch_password      = "admin"   # real login password for the admin user (OpenSearch + Dashboards)
opensearch_admin_user    = "admin"   # optional, default "admin" — separate from opensearch_user (web container runtime user)
opensearch_user_pw       = "..."     # password for the app user weather-man (read-only on weather*)
opensearch_dashboard_ip  = "192.168.8.168"   # IP in all TLS certificates (Dashboard + web)
opensearch_port_external = 19200     # optional, default fits the standard setup
logstash_git_ref         = "<commit SHA or tag in the apws-logstash repo>"
web_git_ref               = "<commit SHA or tag in the apws-web repo>"
dht_git_ref               = "<commit SHA or tag in the apws-dht repo>"
hygrometer_git_ref        = "<commit SHA or tag in the apws-hygrometer repo>"
docker_platform          = "linux/arm64/v8"  # optional, default matches a Raspberry Pi 4/5

# web container: OpenSearch connection + Django secrets (replaces the committed .env in apws-web)
web_secret_key        = "<Django SECRET_KEY>"
allowed_hosts         = "*"                  # comma-separated, no spaces
opensearch_host       = "192.168.8.168"
opensearch_port       = 19200
opensearch_user       = "weather-man"
opensearch_use_ssl    = true
opensearch_ssl_verify = false
web_debug             = false
camera_host           = "192.168.8.168"      # host serving the rpicam-vid MJPEG stream
camera_port           = 8554
```

## Commands

```bash
cd src
tofu init
tofu plan  -parallelism=1 -out=tfplan
tofu apply -parallelism=1 tfplan
```

### Why `-parallelism=1`

The `docker` provider opens SSH connections to the target host for Docker operations — at
the default parallelism (10) that happens for multiple resources at once, and `buildx`
(image builds) itself opens several more connections per build on top of that. If the
target host runs `ufw` with an SSH rate-limit rule (`ufw limit ssh`, the default on many
Raspberry Pi images), this blocks mid-apply with `ssh: connect ... Connection refused`.
Two options:

- use `-parallelism=1` for `plan`/`apply` (safer, but slower), or
- on the target host, swap the limit rule for a normal allow rule:
  ```bash
  sudo ufw status numbered      # find the number(s) of the "22/tcp (v6)? LIMIT IN" rule(s)
  sudo ufw delete <number>      # possibly once each for IPv4 and IPv6
  sudo ufw allow OpenSSH
  ```

## Git-based image builds

`logstash`, `web`, `dht`, and `hygrometer` live as their own projects on GitHub
(`apws-logstash`, `apws-web`, `apws-dht`, `apws-hygrometer`) instead of locally in this
repo. The `kreuzwerker/docker` provider, however, does **not** support a Git URL as a build
context (unlike `docker build` on the CLI) — a `build_context` with `https://...git` fails
on apply with "dockerfile not found at path: ...".

That's why `modules/git_checkout` clones the respective repo locally to
`src/.build/<repo>` (via `terraform_data` + `local-exec`, triggered by `*_git_ref`), before
`modules/docker_image` builds from there. `logstash_git_ref`/`web_git_ref`/`dht_git_ref`/
`hygrometer_git_ref` each pin a commit SHA or tag — no default, must be set in
`terraform.tfvars`. `src/.build/` is gitignored.

## Deployed services

| Service                 | External port | URL / notes                                    |
|-------------------------|---------------|------------------------------------------|
| `opensearch`             | 19200         | `https://<ssh_host>:19200` (admin / `opensearch_password`) |
| `opensearch-dashboards`  | 15601         | `https://<ssh_host>:15601` (admin / `opensearch_password`) |
| `logstash`               | 5044          | Beats input                             |
| `web`                    | 8000          | `https://<ssh_host>:8000`               |
| `dht`                    | –             | No exposed port; reads via GPIO (`/dev/gpiochip0`), writes to OpenSearch |
| `hygrometer`             | –             | No exposed port; reads via I2C (`/dev/i2c-1`) + GPIO, writes to OpenSearch |
| `rpicam-vid` (systemd, not a container) | 8554 | `tcp://<ssh_host>:8554` MJPEG stream, consumed by `web` via `camera_host`/`camera_port` |

## Camera stream: `rpicam-vid` as a host systemd service

Unlike the other services, `rpicam-vid` doesn't run in a container — `rpicam-vid` needs
direct access to the Pi's camera module, which isn't reliably passed through Docker.
`modules/systemd_service` (`module.rpicam_vid_service` in `src/main.tf`) instead installs
and enables a systemd unit directly on the target host over the same SSH connection: it
templates `unit.tftpl`, uploads it via a `file` provisioner, then moves it into
`/etc/systemd/system/` and runs `systemctl daemon-reload`/`enable --now` via
`remote-exec` — hence the passwordless-sudo requirement in
[Prerequisites](#prerequisites). The `web` container consumes the resulting MJPEG stream
via the `camera_host`/`camera_port` variables (not auto-derived from `ssh_host`, since the
stream may be served from a different interface).

## TLS: own root CA instead of Let's Encrypt

All three HTTPS services (OpenSearch API, Dashboards, `web`) use certificates signed by
a locally generated, self-owned root CA (`modules/tls_ca` + `modules/tls_cert`,
`hashicorp/tls`) — **no** more self-signed certificate per service, and **no** Let's
Encrypt: public CAs don't issue certificates for plain IP addresses (only for validated
domain names), but the services here sit behind a private IP.

For the OpenSearch API itself (`docker_container.opensearch`), three `upload` blocks
overwrite the demo certificates shipped in the image directly in the container filesystem
(`/usr/share/opensearch/config/{root-ca,esnode,esnode-key}.pem`) — these are exactly the
files that `plugins.security.ssl.{http,transport}.*` reference in the security demo config.
The certificate and trust store (`root-ca.pem`) must always be swapped together, otherwise
the node no longer trusts its own new certificate on startup. Since `upload` contents force
a replace with the `docker_container` provider, every certificate change here recreates the
container once (data in the separate `docker_volume.opensearch_data` is unaffected).

Extract the root CA certificate once and import it as trusted in your browser/OS:

```bash
cd src
tofu output -raw root_ca_cert_pem > ../apbs-root-ca.pem
```

After that, the certificate warning disappears permanently for every service whose
certificate was signed by this CA — not just dismissed once per certificate.

`web` (Gunicorn) terminates TLS itself (`--certfile`/`--keyfile`, overridden via `command`
in the `docker_container.web` block) — without having to touch the `apws-web` repo for it,
since Gunicorn's `CMD` in the Dockerfile is a simple, overridable array.

## App user: `weather-man`

`modules/opensearch` additionally creates an OpenSearch-internal app user `weather-man`
(`opensearch_user_pw`), with a role `app_reader` that only grants read access
(`get`/`read`/`search`/`indices_monitor`) on indices matching the pattern `weather*` —
`indices_monitor` covers index-scoped stats/settings (e.g. `GET /weather*/_stats/store` for
index size), but is **not** enough for `_cat/indices`, since that additionally needs the
cluster permission `cluster:monitor/state`, which this role deliberately doesn't have —
managed via the `opensearch-project/opensearch` Terraform provider (configuration in
`src/provider.tf`, root module). The provider now verifies the OpenSearch REST API itself
against the private root CA (`cacert_file`, no more `insecure = true`): since the provider
expects a file path rather than PEM content for that, a `local_file` resource
(`local_file.root_ca_cert`) writes the CA once to `src/.build/root-ca.pem`. The admin login
for provisioning (`opensearch_admin_user`, default `admin`) is deliberately a separate
variable from `opensearch_user` (the `web` container's runtime user) — otherwise, later
downgrading `opensearch_user` to `weather-man` would break Terraform's own provisioning
(creating roles/users requires admin rights). See also [Gotchas](#gotchas) for the one-time
bootstrap of this file.

## Gotchas

- **Bootstrap vs. login password:** `OPENSEARCH_INITIAL_ADMIN_PASSWORD` is only used on the
  very first start of an empty security index, but must independently pass OpenSearch's
  password strength check (otherwise crash loop). That's what the separate variable
  `opensearch_password` (`modules/opensearch/variables.tf`.
- **Volume/network survive container replaces:** `docker_volume.opensearch_data` and
  `docker_network.opensearch_net` are separate state resources; a replace of
  `docker_container.opensearch*` (e.g. due to `env` changes) does not recreate the data.
- **Module moves need `moved` blocks or `tofu state mv`.** If a resource is moved into
  another module without updating the state accordingly, OpenTofu plans a destroy (old
  address) + create (new address) for the same real resource — a downtime/data-loss risk
  for running containers/networks/volumes.
- **ECDSA default curve:** `modules/tls_cert` explicitly sets `ecdsa_curve = "P256"`. The
  provider default (`P224`) is not supported by many TLS stacks (including Node.js/OpenSSL,
  hence also OpenSearch Dashboards) and makes the TLS handshake fail silently.
- **`docker_image.build.context` does not accept Git URLs** — see
  [Git-based image builds](#git-based-image-builds).
- **`tofu import` of `docker_container` resources doesn't cleanly restore `env`/
  `networks_advanced`/`volumes`/`upload`** — a freshly imported container will almost
  always show `must be replaced` on the next `plan`, even without a real config change.
  This is a provider limitation, not a config error; the replace is usually harmless in
  content (same image/env/network), but a real container restart.
- **Provider configuration only belongs in the root, never in a child module.** A
  `provider "opensearch" { ... }` block in `modules/opensearch` next to the one in the root
  leads to `Error: Duplicate provider configuration`. Root provider configurations are
  automatically inherited by all child modules, no explicit pass-through needed.
- **Demo certificates of the OpenSearch security config are baked into the image, not
  regenerated on every container start.** `esnode.pem`/`root-ca.pem` stay identical across
  container restarts unless overwritten via `upload` — that's why the REST API (port 19200)
  was, TLS-wise, completely independent of the CA rollout for Dashboards/`web`, even though
  all three use the same root CA mechanism in the code.
- **Declaring a new variable in a child module is not enough.** `terraform.tfvars` only
  fills root variables. Every new variable needs three parts: declaration in the root
  `variables.tf`, pass-through in the root `main.tf` module block, and the declaration in
  the child module itself — miss one and `plan` breaks with "Missing required argument" or
  the value never arrives.
- **The `opensearch` provider's `cacert_file` needs a one-time bootstrap.** The file
  (`src/.build/root-ca.pem`) is itself only created by `local_file.root_ca_cert` — but even
  the `plan` refresh of the already existing `opensearch_role`/`opensearch_user`/
  `opensearch_roles_mapping` resources needs it beforehand, otherwise the provider fails
  with `HEAD healthcheck failed`. This only affects the very first `plan`/`apply` on a
  machine where `src/.build/root-ca.pem` doesn't exist yet (fresh checkout, or if the root
  CA is ever regenerated). Fix once:
  ```bash
  cd src
  tofu apply -target=local_file.root_ca_cert -auto-approve
  ```
  If there are still open `moved` blocks in the state at that point, OpenTofu lists the
  additionally required `-target` flags in the error message itself. After that,
  `plan`/`apply` continue normally without repeating the trick — the file stays in place
  (gitignored, `src/.build/`), and the root CA doesn't change again (10 years validity).
