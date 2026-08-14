# tls_cert

Erzeugt einen privaten Schlüssel + ein Zertifikat, das von einer eigenen Root-CA
(`hashicorp/tls`) signiert wird — siehe [`tls_ca`](../tls_ca/README.md). Kein selbstsigniertes
Zertifikat mehr, dadurch entfällt die Browser-Vertrauenswarnung, sobald die Root-CA einmal
importiert ist.

## Beispiel

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
  validity_period_hours  = 8760 # 1 Jahr
  early_renewal_hours    = 720  # 30 Tage
}
```

## Inputs

| Name                     | Beschreibung                                                                                   | Typ            | Default                                                    |
|---------------------------|---------------------------------------------------------------------------------------------------|----------------|-------------------------------------------------------------|
| `ca_private_key_pem`       | PEM-Private-Key der signierenden CA (z. B. `module.root_ca.private_key_pem`)                     | `string`       | – (sensitive, pflicht)                                       |
| `ca_cert_pem`               | PEM-Zertifikat der signierenden CA (z. B. `module.root_ca.cert_pem`)                              | `string`       | – (pflicht)                                                   |
| `algorithm`                | Schlüssel-Algorithmus (z. B. `ECDSA`, `RSA`)                                                      | `string`       | `"ECDSA"`                                                    |
| `ecdsa_curve`               | ECDSA-Kurve (nur bei `algorithm = ECDSA`) — siehe Hinweis unten                                   | `string`       | `"P256"`                                                     |
| `dns_names`                 | DNS-Namen fürs Zertifikat                                                                         | `list(string)` | `[]`                                                          |
| `ip_addresses`              | IP-Adressen fürs Zertifikat (SAN `iPAddress`-Einträge)                                            | `list(string)` | `[]`                                                          |
| `common_name`               | Common Name des Zertifikats                                                                       | `string`       | –                                                             |
| `organization`              | Organization des Zertifikats                                                                      | `string`       | –                                                             |
| `validity_period_hours`     | Gültigkeitsdauer in Stunden                                                                       | `number`       | `12`                                                          |
| `early_renewal_hours`       | Erneuerung so viele Stunden vor Ablauf                                                            | `number`       | `3`                                                           |
| `allowed_uses`              | Erlaubte Zertifikatsverwendungen                                                                   | `list(string)` | `["key_encipherment", "digital_signature", "server_auth"]`   |

## Outputs

| Name              | Beschreibung                        |
|--------------------|---------------------------------------|
| `cert_pem`          | PEM-kodiertes, CA-signiertes Zertifikat (sensitive) |
| `private_key_pem`   | PEM-kodierter Private Key (sensitive) |

## Hinweise

- **IP vs. DNS-Name:** Soll das Zertifikat für eine reine IP-URL (`https://1.2.3.4/`) gültig
  sein, gehört die Adresse in `ip_addresses`, **nicht** in `dns_names` — Browser matchen eine
  IP-URL gegen den SAN-Typ `iPAddress`, ein `dNSName`-Eintrag mit IP-Inhalt wird ignoriert.
- **ECDSA-Kurve:** Der `hashicorp/tls`-Provider-Default für `algorithm = ECDSA` ist `P224`.
  Diese Kurve wird von vielen TLS-Stacks (u. a. Node.js/OpenSSL) für Server-Zertifikate nicht
  unterstützt und lässt den TLS-Handshake beim Verbindungsaufbau wortlos scheitern — deshalb
  setzt dieses Modul standardmäßig `P256`.
- Kurze `validity_period_hours` (Default `12`) sorgen dafür, dass OpenTofu das Zertifikat bei
  praktisch jedem Apply nach Ablauf/`early_renewal_hours` neu erzeugt — für langlebige Dienste
  bewusst höher setzen (siehe Beispiel oben).
- **Eine Root-CA für mehrere Leaf-Zertifikate:** `module "root_ca"` einmal instanziieren und an
  mehrere `tls_cert`-Aufrufe (Dashboard, `web`, künftige Dienste) weiterreichen — die Root-CA
  muss dann nur einmal pro Client importiert werden, nicht pro Dienst.
