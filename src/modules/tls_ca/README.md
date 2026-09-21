# tls_ca

Creates a private root CA (`hashicorp/tls`): a private key + a self-signed CA certificate
(`is_ca_certificate = true`). Doesn't sign anything itself — pass it to
[`tls_cert`](../tls_cert/README.md) as `ca_private_key_pem`/`ca_cert_pem` for that.

## Example

```hcl
module "root_ca" {
  source       = "./modules/tls_ca"
  common_name  = "apbs Homelab Root CA"
  organization = "apbs"
}
```

## Inputs

| Name                    | Description                                    | Type     | Default              |
|--------------------------|---------------------------------------------------|----------|------------------------|
| `common_name`             | Common name of the CA certificate                 | `string` | –                      |
| `organization`            | Organization of the CA certificate                | `string` | –                      |
| `algorithm`               | Key algorithm (e.g. `ECDSA`, `RSA`)                | `string` | `"ECDSA"`              |
| `ecdsa_curve`              | ECDSA curve (only used when `algorithm = ECDSA`)  | `string` | `"P256"`               |
| `validity_period_hours`    | Validity period in hours                          | `number` | `87600` (10 years)     |
| `early_renewal_hours`      | Renew this many hours before expiry               | `number` | `720`                  |

## Outputs

| Name              | Description                                                                 |
|--------------------|---------------------------------------------------------------------------------|
| `cert_pem`          | PEM CA certificate — **not sensitive**, this is exactly what gets imported as a trusted root on client devices |
| `private_key_pem`   | PEM private key of the CA (sensitive) — signs leaf certificates, never distributed to clients |

## Notes

- **One-time import:** Extract `cert_pem` via `tofu output -raw root_ca_cert_pem > ca.pem`
  (root `outputs.tf`) and import it once as a trusted root CA in the browser/OS. After that,
  the certificate warning disappears permanently for every service whose leaf certificate is
  signed by this CA — not just a one-time dismissal per certificate.
- **Why not a public CA (e.g. Let's Encrypt):** The services are only reachable via private IP,
  and public CAs don't issue certificates for plain IP addresses, only for validated domain
  names.
