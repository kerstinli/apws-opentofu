# tls_cert

Creates a private key + a certificate signed by its own root CA (`hashicorp/tls`) — see
[`tls_ca`](../tls_ca/README.md). No more self-signed certificate, so the browser trust warning
goes away once the root CA has been imported once.

## Example

```hcl
module "root_ca" {
  source       = "./modules/tls_ca"
  common_name  = "apbs Homelab Root CA"
  organization = "apbs"
}

module "opensearch_dashboard_cert" {
  source                 = "./modules/tls_cert"
  ca_private_key_pem     = module.root_ca.private_key_pem
  ca_cert_pem            = module.root_ca.cert_pem
  ip_addresses           = ["192.168.8.168"]
  common_name            = "192.168.8.168"
  organization           = "OpenSearch Dashboard"
  validity_period_hours  = 8760 # 1 year
  early_renewal_hours    = 720  # 30 days
}
```

## Inputs

| Name                    | Description                                                                                | Type           | Default                                                    |
|--------------------------|-------------------------------------------------------------------------------------------------|----------------|-------------------------------------------------------------|
| `ca_private_key_pem`      | PEM private key of the signing CA (e.g. `module.root_ca.private_key_pem`)                      | `string`       | – (sensitive, required)                                     |
| `ca_cert_pem`             | PEM certificate of the signing CA (e.g. `module.root_ca.cert_pem`)                             | `string`       | – (required)                                                 |
| `algorithm`               | Key algorithm (e.g. `ECDSA`, `RSA`)                                                             | `string`       | `"ECDSA"`                                                    |
| `ecdsa_curve`             | ECDSA curve (only used when `algorithm = ECDSA`) — see note below                              | `string`       | `"P256"`                                                     |
| `dns_names`               | DNS names for the certificate                                                                   | `list(string)` | `[]`                                                          |
| `ip_addresses`            | IP addresses for the certificate (SAN `iPAddress` entries)                                     | `list(string)` | `[]`                                                          |
| `common_name`             | Common name of the certificate                                                                  | `string`       | –                                                             |
| `organization`            | Organization of the certificate                                                                 | `string`       | –                                                             |
| `validity_period_hours`   | Validity period in hours                                                                        | `number`       | `12`                                                          |
| `early_renewal_hours`     | Renew this many hours before expiry                                                             | `number`       | `3`                                                           |
| `allowed_uses`            | Allowed certificate uses                                                                        | `list(string)` | `["key_encipherment", "digital_signature", "server_auth"]`   |

## Outputs

| Name              | Description                         |
|--------------------|---------------------------------------|
| `cert_pem`          | PEM-encoded, CA-signed certificate (sensitive) |
| `private_key_pem`   | PEM-encoded private key (sensitive) |

## Notes

- **IP vs. DNS name:** If the certificate needs to be valid for a plain IP URL
  (`https://1.2.3.4/`), the address belongs in `ip_addresses`, **not** `dns_names` — browsers
  match an IP URL against the SAN type `iPAddress`; a `dNSName` entry containing an IP is
  ignored.
- **ECDSA curve:** The `hashicorp/tls` provider default for `algorithm = ECDSA` is `P224`. This
  curve isn't supported by many TLS stacks (including Node.js/OpenSSL) for server certificates
  and makes the TLS handshake fail silently on connect — so this module defaults to `P256`
  instead.
- Short `validity_period_hours` (default `12`) means OpenTofu recreates the certificate on
  practically every apply once it's past expiry/`early_renewal_hours` — set it deliberately
  higher for long-lived services (see the example above).
- **One root CA for multiple leaf certificates:** Instantiate `module "root_ca"` once and pass
  it into multiple `tls_cert` calls (dashboard, `web`, future services) — the root CA then only
  needs to be imported once per client, not once per service.
