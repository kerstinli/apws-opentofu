# systemd_service

Installs and enables a systemd unit directly on the target host — not in a container, but via
SSH `file` and `remote-exec` provisioners on `terraform_data`. Exists for services that don't
have reliable Docker access to host hardware (e.g. `rpicam-vid` for the camera module).

## Example

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

| Name          | Description                                        | Type     | Default    |
|---------------|------------------------------------------------------|----------|------------|
| `ssh_host`    | Target host for the SSH connection                   | `string` | –          |
| `ssh_user`    | SSH user on the target host (needs passwordless sudo) | `string` | –          |
| `name`        | Name of the systemd unit (without `.service`)         | `string` | –          |
| `description` | Description of the unit                               | `string` | –          |
| `exec_start`  | Full `ExecStart` command                               | `string` | –          |
| `restart`     | systemd `Restart` policy                               | `string` | `"always"` |

## Outputs

| Name   | Description                        |
|--------|--------------------------------------|
| `name` | Name of the installed systemd unit |

## Notes

- **Passwordless sudo required:** The `remote-exec` provisioner runs `sudo mv`,
  `sudo systemctl daemon-reload`, and `sudo systemctl enable --now` without an interactive
  password — `ssh_user` needs a matching `sudoers` rule on the target host for this.
- **No Docker:** Unlike every other service in this project, the unit runs directly on the
  host, not in a container — needed when hardware (here: the camera module) can't be reliably
  passed through Docker.
- **`triggers_replace`:** If `exec_start` or `restart` changes, `terraform_data.this` rewrites
  and reinstalls the unit file and restarts the service (`enable --now` runs again). Other
  attributes (e.g. `name`, `description`) don't trigger a replay without a trigger change.
