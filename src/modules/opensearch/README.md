# opensearch

Deployt einen Single-Node OpenSearch-Cluster samt OpenSearch Dashboards (mit TLS) auf dem
Zielhost: eigenes Docker-Netzwerk, persistentes Volume für die Daten, die beiden Container,
sowie einen App-User (`weather-man`) mit read-only-Zugriff auf `weather*`-Indizes.

## Beispiel

```hcl
module "opensearch" {
  source                   = "./modules/opensearch"
  opensearch_password      = var.opensearch_password
  opensearch_user_pw       = var.opensearch_user_pw
  opensearch_port_external = var.opensearch_port_external
  dashboard_cert_pem       = module.opensearch_dashboard_cert.cert_pem
  dashboard_key_pem        = module.opensearch_dashboard_cert.private_key_pem
}
```

## Inputs

| Name                              | Beschreibung                                                                                  | Typ      | Default              |
|------------------------------------|--------------------------------------------------------------------------------------------------|----------|----------------------|
| `opensearch_password`              | Echtes Admin-Login-Passwort (OpenSearch + Dashboards)                                            | `string` | – (sensitive)         |
| `opensearch_user_pw`                | Passwort für den App-User `weather-man`                                                          | `string` | – (sensitive)         |
| `opensearch_bootstrap_password`    | Nur für OpenSearchs Start-Validierung (`OPENSEARCH_INITIAL_ADMIN_PASSWORD`) — siehe Hinweis unten | `string` | `"Bootstrap#0000"` (sensitive) |
| `dashboard_cert_pem`                | PEM-Zertifikat für Dashboards-TLS                                                                | `string` | – (sensitive)         |
| `dashboard_key_pem`                 | PEM-Private-Key für Dashboards-TLS                                                               | `string` | – (sensitive)         |
| `network_name`                      | Name des Docker-Netzwerks                                                                        | `string` | `"opensearch-network"` |
| `volume_name`                       | Name des Docker-Volumes für die Daten                                                            | `string` | `"opensearch-data"`   |
| `opensearch_port_external`          | Externer Port der OpenSearch-API                                                                 | `number` | `19200`               |
| `dashboards_port_external`          | Externer Port von Dashboards                                                                     | `number` | `15601`               |

## Outputs

| Name                      | Beschreibung                          |
|----------------------------|----------------------------------------|
| `opensearch_container_id`  | Container-ID des OpenSearch-Nodes     |
| `dashboards_container_id`  | Container-ID von OpenSearch Dashboards |
| `network_name`              | Name des Docker-Netzwerks — andere Container joinen darüber (z. B. `logstash`) |

## Hinweise

- **Bootstrap- vs. Login-Passwort:** `OPENSEARCH_INITIAL_ADMIN_PASSWORD` wird nur beim
  allerersten Start eines leeren Security-Index verwendet, muss aber unabhängig davon
  OpenSearchs Passwort-Stärke-Prüfung bestehen (sonst Crash-Loop). Deshalb die getrennte
  Variable `opensearch_bootstrap_password` — das tatsächliche Login-Passwort ist immer
  `opensearch_password`.
- **TLS:** `dashboard_cert_pem`/`dashboard_key_pem` werden per `upload`-Block direkt in den
  Dashboards-Container geschrieben (kein Bind-Mount nötig). Passendes Zertifikat liefert das
  [`tls_cert`](../tls_cert/README.md)-Modul — Erzeugung dort **muss** `ip_addresses`
  (nicht `dns_names`) für eine reine IP-URL wie `https://<host>:15601/` nutzen, sonst matcht
  der Browser das SAN nicht.
- **Persistenz:** `docker_volume.opensearch_data` und `docker_network.opensearch_net` sind
  eigene Ressourcen — ein Replace der Container (z. B. wegen `env`-Änderungen) legt die Daten
  nicht neu an.
- **App-User RBAC:** `opensearch_role.reader` (`app_reader`) erlaubt nur `index_patterns =
  ["weather*"]`, `opensearch_user.reader` (`weather-man`) und `opensearch_roles_mapping.reader`
  verknüpfen User und Rolle. Diese Ressourcen brauchen den `opensearch-project/opensearch`-
  Provider — dessen Konfiguration (`url`/`username`/`password`/`insecure`) gehört in den
  **Root**-`provider.tf`, nicht in dieses Modul: Child-Module dürfen laut OpenTofu/Terraform
  keine eigene `provider`-Blockkonfiguration deklarieren, wenn der Root bereits eine für
  denselben Provider hat (`Duplicate provider configuration`-Fehler). Der `opensearch`-Provider
  muss dabei auf `https://` + `insecure = true` zeigen — die OpenSearch-REST-API läuft mit
  aktiviertem Security-Plugin auf einem selbstsignierten Demo-Zertifikat, unabhängig vom
  CA-signierten Dashboard-Zertifikat.
