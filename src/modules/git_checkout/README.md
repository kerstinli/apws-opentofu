# git_checkout

Clones a Git repository locally on the machine running `tofu apply` (`terraform_data` +
`local-exec`) and checks out a fixed ref (tag or commit SHA). Exists because the
`kreuzwerker/docker` provider does **not accept a Git URL as a `docker_image` `build_context`**
— unlike `docker build` on the CLI, the string is interpreted as a local path. See
[`docker_image`](../docker_image/README.md).

## Example

```hcl
module "logstash_checkout" {
  source       = "./modules/git_checkout"
  repo_url     = "https://github.com/kerstinli/apws-logstash.git"
  ref          = var.logstash_git_ref
  checkout_dir = "${path.module}/.build/apws-logstash"
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

| Name           | Description                                                                    | Type     | Default |
|----------------|---------------------------------------------------------------------------------|----------|---------|
| `repo_url`     | Git repository URL to clone                                                    | `string` | –       |
| `ref`          | Git tag or commit SHA to check out                                             | `string` | –       |
| `checkout_dir` | Local directory to clone into (wiped and recreated when `repo_url`/`ref` change) | `string` | –       |

## Outputs

| Name   | Description                        |
|--------|-------------------------------------|
| `path` | Local path of the checked-out repo |

## Notes

- `checkout_dir` is wiped via `rm -rf` and re-cloned every time the trigger
  (`repo_url`/`ref`) changes — don't store anything important there. Recommended:
  `${path.module}/.build/<repo>`, which the project already ignores via `src/.build/` in
  `.gitignore`.
- `ref` has no default — deliberately no `main`/`master`, to keep builds reproducible
  (pin a commit SHA or tag in `terraform.tfvars`).
