# git_checkout

Klont ein Git-Repository lokal auf die Maschine, die `tofu apply` ausführt (`terraform_data` +
`local-exec`), und checkt einen festen Ref (Tag oder Commit-SHA) aus. Existiert, weil der
`kreuzwerker/docker`-Provider **keine Git-URL als `docker_image`-`build_context`** akzeptiert —
anders als `docker build` auf der CLI wird der String als lokaler Pfad interpretiert. Siehe
[`docker_image`](../docker_image/README.md).

## Beispiel

```hcl
module "logstash_checkout" {
  source       = "./modules/git_checkout"
  repo_url     = "https://github.com/kerstinli/apbs-logstash.git"
  ref          = var.logstash_git_ref
  checkout_dir = "${path.module}/.build/apbs-logstash"
}

module "logstash_image" {
  source           = "./modules/docker_image"
  name             = "logstash:8.19.18"
  build_context    = "${module.logstash_checkout.path}/src"
  build_dockerfile = "Dockerfile"
  triggers = {
    git_ref = var.logstash_git_ref
  }
}
```

## Inputs

| Name              | Beschreibung                                                        | Typ      | Default |
|--------------------|--------------------------------------------------------------------|----------|---------|
| `repo_url`          | Git-Repository-URL, die geklont wird                               | `string` | –       |
| `ref`                | Git-Tag oder Commit-SHA, auf den ausgecheckt wird                  | `string` | –       |
| `checkout_dir`       | Lokales Verzeichnis, in das geklont wird (wird bei jedem Apply neu angelegt) | `string` | –       |

## Outputs

| Name    | Beschreibung                     |
|----------|-------------------------------------|
| `path`    | Lokaler Pfad des ausgecheckten Repos |

## Hinweise

- `checkout_dir` wird bei jedem Trigger-Wechsel (`repo_url`/`ref`) per `rm -rf` geleert und neu
  geklont — dort nichts Wichtiges ablegen. Empfehlung: `${path.module}/.build/<repo>`, das
  Projekt ignoriert `src/.build/` bereits in `.gitignore`.
- `ref` ohne Default — bewusst kein `main`/`master`, damit Builds reproduzierbar bleiben
  (Commit-SHA oder Tag pinnen, in `terraform.tfvars`).
