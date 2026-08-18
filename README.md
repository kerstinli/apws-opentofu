# apbs-opentofu

OpenTofu-Setup für Docker-Dienste (OpenSearch, OpenSearch Dashboards, Logstash, Web) auf einem
per SSH erreichbaren Docker-Host (z. B. Raspberry Pi). Der `docker`-Provider verbindet sich
über `ssh://<ssh_user>@<ssh_host>:22`, es braucht also keinen offenen Docker-Port — nur SSH.

`logstash` und `web` werden nicht mehr aus lokalen Dateien gebaut, sondern aus eigenen
GitHub-Repos (`apbs-logstash`, `apbs-web`) — siehe [Git-basierte Image-Builds](#git-basierte-image-builds).

## Voraussetzungen

- OpenTofu installiert
- SSH-Public-Key-Zugriff auf den Zielhost, `ssh_user` muss dort in der `docker`-Gruppe sein
- Auf dem Zielhost für OpenSearch einmalig:
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  # dauerhaft: in /etc/sysctl.conf eintragen
  ```
- `git` lokal installiert (wird für die Image-Builds gebraucht, siehe unten)

## Konfiguration

`src/terraform.tfvars` (nicht versioniert):

```hcl
ssh_host                 = "192.168.8.168"
ssh_user                 = "pi"
opensearch_password      = "admin"   # echtes Login-Passwort für den admin-User (OpenSearch + Dashboards)
opensearch_user_pw       = "..."     # Passwort für den App-User weather-man (read-only auf weather*)
opensearch_dashboard_ip  = "192.168.8.168"   # IP in allen TLS-Zertifikaten (Dashboard + web)
opensearch_port_external = 19200     # optional, Default passt für Standard-Setup
logstash_git_ref         = "<commit-sha oder tag im apbs-logstash-Repo>"
web_git_ref               = "<commit-sha oder tag im apbs-web-Repo>"

# web-Container: OpenSearch-Anbindung + Django-Secrets (ersetzt das committete .env in apbs-web)
web_secret_key        = "<Django SECRET_KEY>"
allowed_hosts         = "*"                  # kommagetrennt, ohne Leerzeichen
opensearch_host       = "192.168.8.168"
opensearch_port       = 19200
opensearch_user       = "weather-man"
opensearch_use_ssl    = true
opensearch_ssl_verify = false
web_debug             = false
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

## Git-basierte Image-Builds

`logstash` und `web` liegen als eigene Projekte in GitHub (`apbs-logstash`, `apbs-web`) statt
lokal in diesem Repo. Der `kreuzwerker/docker`-Provider unterstützt aber **keine** Git-URL als
Build-Context (anders als `docker build` auf der CLI) — ein `build_context` mit `https://...git`
scheitert beim Apply mit "dockerfile not found at path: ...".

Deshalb klont `modules/git_checkout` das jeweilige Repo lokal nach `src/.build/<repo>` (per
`terraform_data` + `local-exec`, getriggert über den `*_git_ref`), bevor `modules/docker_image`
von dort baut. `logstash_git_ref`/`web_git_ref` pinnen jeweils einen Commit-SHA oder Tag — kein
Default, muss in `terraform.tfvars` gesetzt werden. `src/.build/` ist gitignored.

## Deployte Dienste

| Dienst                  | externer Port | URL                                    |
|-------------------------|---------------|------------------------------------------|
| `opensearch`             | 19200         | `https://<ssh_host>:19200` (admin / `opensearch_password`) |
| `opensearch-dashboards`  | 15601         | `https://<ssh_host>:15601` (admin / `opensearch_password`) |
| `logstash`               | 5044          | Beats-Input                             |
| `web`                    | 8000          | `https://<ssh_host>:8000`               |

## TLS: eigene Root-CA statt Let's Encrypt

Alle drei HTTPS-Dienste (OpenSearch-API, Dashboards, `web`) nutzen Zertifikate, die von einer
eigenen, lokal erzeugten Root-CA signiert sind (`modules/tls_ca` + `modules/tls_cert`,
`hashicorp/tls`) — **kein** selbstsigniertes Zertifikat mehr pro Dienst, und **kein** Let's
Encrypt: öffentliche CAs stellen keine Zertifikate für reine IP-Adressen aus (nur für validierte
Domainnamen), die Dienste hängen hier aber an einer privaten IP.

Für die OpenSearch-API selbst (`docker_container.opensearch`) überschreiben drei `upload`-Blöcke
die im Image mitgelieferten Demo-Zertifikate direkt im Container-Dateisystem
(`/usr/share/opensearch/config/{root-ca,esnode,esnode-key}.pem`) — das sind genau die Dateien,
auf die `plugins.security.ssl.{http,transport}.*` in der Security-Demo-Config verweist. Zertifikat
und Trust-Store (`root-ca.pem`) müssen dabei immer zusammen ausgetauscht werden, sonst vertraut
der Node beim Start seinem eigenen neuen Zertifikat nicht mehr. Da `upload`-Inhalte beim
`docker_container`-Provider ein Replace erzwingen, legt jede Zertifikatsänderung hier den
Container einmal neu an (Daten im separaten `docker_volume.opensearch_data` bleiben davon
unberührt).

Root-CA-Zertifikat einmalig extrahieren und in Browser/OS als vertrauenswürdig importieren:

```bash
cd src
tofu output -raw root_ca_cert_pem > ../apbs-root-ca.pem
```

Danach verschwindet die Zertifikatswarnung dauerhaft für jeden Dienst, dessen Zertifikat von
dieser CA signiert wurde — nicht nur einmalig pro Zertifikat wegklicken.

`web` (Gunicorn) terminiert TLS direkt selbst (`--certfile`/`--keyfile`, per `command` im
`docker_container.web`-Block überschrieben) — ohne das `apbs-web`-Repo dafür anfassen zu
müssen, da Gunicorns `CMD` im Dockerfile ein einfaches, überschreibbares Array ist.

## App-User: `weather-man`

`modules/opensearch` legt zusätzlich einen OpenSearch-internen App-User `weather-man` an
(`opensearch_user_pw`), mit einer Rolle `app_reader`, die nur Lesezugriff
(`get`/`read`/`search`/`indices_monitor`) auf Indizes nach dem Muster `weather*` erlaubt —
`indices_monitor` deckt index-scoped Stats/Settings ab (z. B. `GET /weather*/_stats/store` für
die Indexgröße), reicht aber **nicht** für `_cat/indices`, da der zusätzlich die Cluster-Permission
`cluster:monitor/state` braucht, die diese Rolle bewusst nicht hat — verwaltet über den
`opensearch-project/opensearch`-Terraform-Provider (Konfiguration in `src/provider.tf`,
Root-Modul; nutzt weiterhin `insecure = true`, da der Provider selbst keine eigene
CA-Datei zum Verifizieren akzeptiert — unabhängig davon liefert die OpenSearch-REST-API seit der
CA-Umstellung oben ein von der privaten Root-CA signiertes Zertifikat, das andere Clients, die
eine CA-Datei konfigurieren können (z. B. ein MCP-Client für OpenSearch), regulär verifizieren
können, ohne TLS-Verify abzuschalten).

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
- **`docker_image.build.context` akzeptiert keine Git-URLs** — siehe
  [Git-basierte Image-Builds](#git-basierte-image-builds).
- **`tofu import` von `docker_container`-Ressourcen bringt `env`/`networks_advanced`/
  `volumes`/`upload` nicht sauber zurück** — ein frisch importierter Container zeigt beim
  nächsten `plan` fast immer `must be replaced`, auch ohne echte Config-Änderung. Provider-
  Einschränkung, kein Config-Fehler; der Replace ist i. d. R. inhaltlich harmlos (gleiches
  Image/Env/Netzwerk), aber ein echter Container-Neustart.
- **Provider-Konfiguration gehört nur in den Root, nie in ein Child-Modul.** Ein
  `provider "opensearch" { ... }`-Block in `modules/opensearch` neben dem im Root führt zu
  `Error: Duplicate provider configuration`. Root-Provider-Konfigurationen werden automatisch
  an alle Kind-Module vererbt, kein explizites Durchreichen nötig.
- **Demo-Zertifikate der OpenSearch-Security-Config sind im Image gebacken, nicht pro
  Container-Start neu generiert.** `esnode.pem`/`root-ca.pem` bleiben über Container-Restarts
  identisch, solange sie nicht per `upload` überschrieben werden — deshalb war die REST-API
  (Port 19200) TLS-mäßig komplett unabhängig vom CA-Rollout für Dashboards/`web`, obwohl alle
  drei denselben Root-CA-Mechanismus im Code verwenden.
- **Neue Variable in einem Kind-Modul deklariert ist nicht genug.** `terraform.tfvars` füllt
  nur Root-Variablen. Jede neue Variable braucht drei Teile: Deklaration in Root-`variables.tf`,
  Durchreichen im Root-`main.tf`-Modulblock, und die Deklaration im Kind-Modul selbst — fehlt
  eines davon, bricht `plan` mit "Missing required argument" oder der Wert kommt nie an.
