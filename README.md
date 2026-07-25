# apbs-opentofu

OpenTofu-Setup für Docker-Dienste (OpenSearch, OpenSearch Dashboards, Logstash) auf einem
per SSH erreichbaren Docker-Host (z. B. Raspberry Pi). Der `docker`-Provider verbindet sich
über `ssh://<ssh_user>@<ssh_host>:22`, es braucht also keinen offenen Docker-Port — nur SSH.

## Voraussetzungen

- OpenTofu installiert
- SSH-Public-Key-Zugriff auf den Zielhost, `ssh_user` muss dort in der `docker`-Gruppe sein
- Auf dem Zielhost für OpenSearch einmalig:
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  # dauerhaft: in /etc/sysctl.conf eintragen
  ```

## Konfiguration

`src/terraform.tfvars`:

```hcl
ssh_host            = "192.168.8.168"
ssh_user            = "pi"
opensearch_password = "admin"   # echtes Login-Passwort für den admin-User (OpenSearch + Dashboards)
```

## Befehle

```bash
cd src
tofu init
tofu plan  -parallelism=1 -out=tfplan
tofu apply -parallelism=1 tfplan
```

### Warum `-parallelism=1`

Der `docker`-Provider öffnet für Docker-Operationen SSH-Verbindungen zum Zielhost — bei
Standard-Parallelität (10) parallel für mehrere Ressourcen gleichzeitig, zusätzlich öffnet
`buildx` (Image-Builds) selbst nochmal mehrere Verbindungen pro Build. Läuft auf dem Zielhost
`ufw` mit einer SSH-Rate-Limit-Regel (`ufw limit ssh`, Standard bei vielen Raspberry-Pi-Images),
blockt das mitten im Apply mit `ssh: connect ... Connection refused`. Zwei Optionen:

- `-parallelism=1` bei `plan`/`apply` verwenden (sicherer, aber langsamer), oder
- auf dem Zielhost die Limit-Regel gegen eine normale Allow-Regel tauschen:
  ```bash
  sudo ufw status numbered      # Nummer(n) der "22/tcp (v6)? LIMIT IN"-Regel(n) suchen
  sudo ufw delete <Nummer>      # ggf. für IPv4 und IPv6 je einmal
  sudo ufw allow OpenSSH
  ```

## Deployte Dienste

| Dienst                  | externer Port | URL                                    |
|-------------------------|---------------|-----------------------------------------|
| `opensearch`             | 19200         | `https://<ssh_host>:19200` (admin / `opensearch_password`) |
| `opensearch-dashboards`  | 15601         | `https://<ssh_host>:15601` (admin / `opensearch_password`) |
| `logstash`               | 5044          | Beats-Input                             |

Das Dashboards-Zertifikat (`module.opensearch_dashboard_cert`, `modules/tls_cert`) ist
selbstsigniert — der Browser zeigt beim ersten Aufruf eine Vertrauenswarnung, die einmalig
akzeptiert werden muss.

## Stolpersteine

- **Bootstrap- vs. Login-Passwort:** `OPENSEARCH_INITIAL_ADMIN_PASSWORD` wird nur beim
  allerersten Start eines leeren Security-Index verwendet, muss aber unabhängig davon
  OpenSearchs Passwort-Stärke-Prüfung bestehen (sonst Crash-Loop). Dafür gibt es die separate
  Variable `opensearch_bootstrap_password` (`modules/opensearch/variables.tf`, Default
  `Bootstrap#0000`) — das eigentliche Login-Passwort bleibt `opensearch_password`.
- **Volume/Netzwerk überleben Container-Replaces:** `docker_volume.opensearch_data` und
  `docker_network.opensearch_net` sind eigene State-Ressourcen; ein Replace von
  `docker_container.opensearch*` (z. B. wegen `env`-Änderungen) legt die Daten nicht neu an.
- **Modul-Umzüge brauchen `moved`-Blöcke bzw. `tofu state mv`.** Wird eine Ressource in ein
  anderes Modul verschoben, ohne das im State nachzuziehen, plant OpenTofu destroy (alte
  Adresse) + create (neue Adresse) für dieselbe reale Ressource — bei laufenden
  Containern/Netzwerken/Volumes ein Downtime-/Datenverlustrisiko.
- **ECDSA-Default-Kurve:** `modules/tls_cert` setzt `ecdsa_curve = "P256"` explizit. Der
  Provider-Default (`P224`) wird von vielen TLS-Stacks (u. a. Node.js/OpenSSL, also auch
  OpenSearch Dashboards) nicht unterstützt und lässt den TLS-Handshake wortlos scheitern.
