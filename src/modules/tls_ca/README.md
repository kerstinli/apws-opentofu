# tls_ca

Erzeugt eine private Root-CA (`hashicorp/tls`): einen privaten Schlüssel + ein
selbstsigniertes CA-Zertifikat (`is_ca_certificate = true`). Signiert selbst nichts direkt —
dafür an [`tls_cert`](../tls_cert/README.md) als `ca_private_key_pem`/`ca_cert_pem`
weiterreichen.

## Beispiel

```hcl
module "root_ca" {
  source       = "./modules/tls_ca"
  common_name  = "apbs Homelab Root CA"
  organization = "apbs"
}
```

## Inputs

| Name                     | Beschreibung                                     | Typ      | Default   |
|---------------------------|-----------------------------------------------------|----------|-----------|
| `common_name`              | Common Name des CA-Zertifikats                     | `string` | –         |
| `organization`             | Organization des CA-Zertifikats                    | `string` | –         |
| `algorithm`                 | Schlüssel-Algorithmus (z. B. `ECDSA`, `RSA`)       | `string` | `"ECDSA"` |
| `ecdsa_curve`                | ECDSA-Kurve (nur bei `algorithm = ECDSA`)          | `string` | `"P256"`  |
| `validity_period_hours`      | Gültigkeitsdauer in Stunden                        | `number` | `87600` (10 Jahre) |
| `early_renewal_hours`        | Erneuerung so viele Stunden vor Ablauf             | `number` | `720`     |

## Outputs

| Name              | Beschreibung                                                                 |
|--------------------|---------------------------------------------------------------------------------|
| `cert_pem`          | PEM-CA-Zertifikat — **nicht sensitive**, das ist genau das, was auf Client-Geräten als vertrauenswürdige Root importiert wird |
| `private_key_pem`   | PEM-Private-Key der CA (sensitive) — signiert Leaf-Zertifikate, wird nie an Clients verteilt |

## Hinweise

- **Einmaliger Import:** `cert_pem` per `tofu output -raw root_ca_cert_pem > ca.pem` (Root-`outputs.tf`)
  extrahieren und einmalig als vertrauenswürdige Root-CA in Browser/OS importieren. Danach
  verschwindet die Zertifikatswarnung dauerhaft für alle Dienste, deren Leaf-Zertifikat von
  dieser CA signiert ist — nicht nur "einmal wegklicken" pro Zertifikat.
- **Warum keine öffentliche CA (z. B. Let's Encrypt):** Die Dienste sind nur per privater IP
  erreichbar, öffentliche CAs stellen aber keine Zertifikate für bloße IP-Adressen aus, nur für
  Domainnamen mit Validierung.
