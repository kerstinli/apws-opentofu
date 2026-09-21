# opensearch

Deploys a single-node OpenSearch cluster together with OpenSearch Dashboards (with TLS) on
the target host: its own Docker network, a persistent volume for the data, both containers,
plus an app user (`weather-man`) with read-only access to `weather*` and `hygrometer*` indices.

## Example

```hcl
module "opensearch" {
  source                   = "./modules/opensearch"
  opensearch_password      = var.opensearch_password
  opensearch_user_pw       = var.opensearch_user_pw
  opensearch_port_external = var.opensearch_port_external
  dashboard_cert_pem       = module.tls_certs["dashboard"].cert_pem
  dashboard_key_pem        = module.tls_certs["dashboard"].private_key_pem
  root_ca_cert_pem         = module.root_ca.cert_pem
  api_cert_pem             = module.tls_certs["api"].cert_pem
  api_key_pem              = module.tls_certs["api"].private_key_pem
}
```

## Inputs

| Name                               | Description                                                                    | Type     | Default                        |
|-------------------------------------|----------------------------------------------------------------------------------|----------|---------------------------------|
| `opensearch_password`               | Admin login password (OpenSearch + Dashboards)                                  | `string` | – (sensitive)                   |
| `opensearch_user_pw`                | Password for the app user `weather-man`                                        | `string` | – (sensitive)                   |
| `dashboard_cert_pem`                 | PEM certificate for Dashboards TLS                                              | `string` | – (sensitive)                   |
| `dashboard_key_pem`                  | PEM private key for Dashboards TLS                                              | `string` | – (sensitive)                   |
| `root_ca_cert_pem`                   | PEM root CA certificate — installed as the OpenSearch node's trusted CA          | `string` | –                                |
| `api_cert_pem`                       | PEM certificate for the OpenSearch node's HTTP/transport TLS                    | `string` | – (sensitive)                   |
| `api_key_pem`                        | PEM private key for the OpenSearch node's HTTP/transport TLS                    | `string` | – (sensitive)                   |
| `network_name`                       | Docker network name                                                             | `string` | `"opensearch-network"`          |
| `volume_name`                        | Docker volume name for the data                                                 | `string` | `"opensearch-data"`             |
| `opensearch_port_external`           | External port of the OpenSearch API                                             | `number` | `19200`                         |
| `dashboards_port_external`           | External port of Dashboards                                                     | `number` | `15601`                         |
| `opensearch_image_name`              | OpenSearch Docker image name                                                     | `string` | `"opensearchproject/opensearch:3.7.0"` |
| `opensearch_dashboards_image_name`   | OpenSearch Dashboards Docker image name                                         | `string` | `"opensearchproject/opensearch-dashboards:3.7.0"` |
| `opensearch_java_opts`               | Java options for the OpenSearch container                                       | `string` | `"-Xms384m -Xmx384m"`           |
| `opensearch_dashboards_java_opts`    | Java options for the OpenSearch Dashboards container                            | `string` | `"-Xms256m -Xmx256m"`           |
| `opensearch_hosts`                   | Hosts for OpenSearch Dashboards to connect to                                   | `string` | `"https://opensearch:9200"`     |
| `opensearch_dashboards_user`         | Username for OpenSearch Dashboards                                              | `string` | `"admin"`                       |

## Outputs

| Name                       | Description                            |
|------------------------------|------------------------------------------|
| `opensearch_container_id`   | Container ID of the OpenSearch node    |
| `dashboards_container_id`   | Container ID of OpenSearch Dashboards  |
| `network_name`               | Name of the Docker network — other containers join it to reach OpenSearch (e.g. `logstash`) |

## Notes

- **Login password:** `OPENSEARCH_INITIAL_ADMIN_PASSWORD` is used on the first start against
  an empty security index and sets the admin password. After that, `opensearch_password` is
  used for login.
- **TLS:** `dashboard_cert_pem`/`dashboard_key_pem` are written straight into the Dashboards
  container via an `upload` block (no bind mount needed). The [`tls_cert`](../tls_cert/README.md)
  module provides a matching certificate — generation there **must** use `ip_addresses`
  (not `dns_names`) for a plain IP URL like `https://<host>:15601/`, otherwise the browser
  won't match the SAN.
- **Node TLS:** `root_ca_cert_pem`/`api_cert_pem`/`api_key_pem` are written into the
  OpenSearch container as `root-ca.pem`/`esnode.pem`/`esnode-key.pem`, replacing the image's
  bundled demo certificate with a certificate from the project's own CA (see
  [`tls_ca`](../tls_ca/README.md)/[`tls_cert`](../tls_cert/README.md)).
- **Persistence:** `docker_volume.opensearch_data` and `docker_network.opensearch_net` are
  standalone resources — replacing the containers (e.g. due to `env` changes) doesn't recreate
  the data.
- **App-user RBAC:** `opensearch_role.reader` (`app_reader`) only allows `index_patterns =
  ["weather*","hygrometer*]`; `opensearch_user.reader` (`weather-man`) and `opensearch_roles_mapping.reader`
  link the user to the role. These resources need the `opensearch-project/opensearch`
  provider — its configuration (`url`/`username`/`password`/`insecure`) belongs in the
  **root** `provider.tf`, not in this module: per OpenTofu/Terraform, child modules must not
  declare their own `provider` block configuration if the root already has one for the same
  provider (`Duplicate provider configuration` error). The `opensearch` provider must point at
  `https://` + `insecure = true` here — the OpenSearch REST API runs with the security plugin
  enabled on the certificate configured via `api_cert_pem`/`api_key_pem` above (the project's
  own CA, not the OpenSearch image's demo cert), but the provider has no way to trust that
  private CA, so `insecure = true` is required regardless of which certificate is installed.
