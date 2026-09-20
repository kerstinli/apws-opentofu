# systemd_service

Installiert und aktiviert eine systemd-Unit direkt auf dem Zielhost — nicht in einem
Container, sondern per SSH-`file`- und `remote-exec`-Provisioner auf `terraform_data`. Existiert
für Dienste, die keinen zuverlässigen Docker-Zugriff auf Host-Hardware haben (z. B.
`rpicam-vid` aufs Kameramodul).

## Beispiel

```hcl
module "rpicam_vid_service" {
  source      = "./modules/systemd_service"
  ssh_host    = var.ssh_host
  ssh_user    = var.ssh_user
  name        = "rpicam-vid"
  description = "MJPEG camera stream via rpicam-vid"
  exec_start  = "/usr/bin/rpicam-vid --timeout 0 --nopreview --codec mjpeg --width 1280 --height 720 --framerate 30 --quality 85 --inline --listen --output tcp://0.0.0.0:8554"
}
```

## Inputs

| Name          | Beschreibung                                      | Typ      | Default    |
|---------------|----------------------------------------------------|----------|------------|
| `ssh_host`     | Zielhost für die SSH-Verbindung                    | `string` | –          |
| `ssh_user`      | SSH-User auf dem Zielhost (braucht passwortlosen sudo) | `string` | –          |
| `name`          | Name der systemd-Unit (ohne `.service`)            | `string` | –          |
| `description`    | Beschreibung der Unit                              | `string` | –          |
| `exec_start`      | Vollständiger `ExecStart`-Befehl                   | `string` | –          |
| `restart`          | systemd-`Restart`-Policy                          | `string` | `"always"` |

## Outputs

| Name    | Beschreibung                     |
|----------|-------------------------------------|
| `name`    | Name der eingerichteten systemd-Unit |

## Hinweise

- **Passwortloser sudo Pflicht:** Der `remote-exec`-Provisioner führt `sudo mv`,
  `sudo systemctl daemon-reload` und `sudo systemctl enable --now` ohne interaktives
  Passwort aus — `ssh_user` braucht dafür eine passende `sudoers`-Regel auf dem Zielhost.
- **Kein Docker:** Anders als alle anderen Dienste in diesem Projekt läuft die Unit direkt
  auf dem Host, nicht in einem Container — nötig, wenn Hardware (hier: Kameramodul) sich
  nicht zuverlässig durch Docker durchreichen lässt.
- **`triggers_replace`:** Ändert sich `exec_start` oder `restart`, schreibt/installiert
  `terraform_data.this` die Unit-Datei neu und startet den Dienst neu (`enable --now` läuft
  erneut). Andere Attribute (z. B. `name`, `description`) lösen ohne Ref-Änderung kein Replay
  aus.
