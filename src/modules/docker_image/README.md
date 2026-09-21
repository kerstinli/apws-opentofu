# docker_image

Pulls a Docker image, or builds it (if `build_context` is set), on the target host
configured via the `docker` provider.

## Example

```hcl
# Pull
module "opensearch_image" {
  source = "../docker_image"
  name   = "opensearchproject/opensearch:3.7.0"
}

# Build
module "logstash_image" {
  source           = "../docker_image"
  name             = "logstash:8.19.18"
  platform         = "linux/arm64/v8"
  build_context    = path.module
  build_dockerfile = "Dockerfile"
  build_args = {
    LOGSTASH_VERSION = "8.19.18"
  }
  triggers = {
    dockerfile_hash = filesha256("${path.module}/Dockerfile")
  }
}
```

## Inputs

| Name               | Description                                                                              | Type          | Default          |
|--------------------|--------------------------------------------------------------------------------------------|---------------|------------------|
| `name`             | Image name including tag (e.g. `opensearchproject/opensearch:3.7.0`)                       | `string`      | –                |
| `platform`         | Target platform                                                                            | `string`      | `"linux/arm64"`  |
| `keep_locally`     | Keep the image locally after destroy                                                       | `bool`        | `true`           |
| `build_context`    | Path to the build context. If set, the image is built instead of pulled                    | `string`      | `null`           |
| `build_dockerfile` | Dockerfile name relative to `build_context`                                                | `string`      | `"Dockerfile"`   |
| `build_args`       | `--build-arg` values for the build (require matching `ARG` declarations in the Dockerfile) | `map(string)` | `{}`             |
| `triggers`         | Arbitrary map that forces a rebuild when changed (e.g. file hashes of the build context) — the provider doesn't otherwise detect changes to the build context | `map(string)` | `{}`             |

## Outputs

| Name       | Description                      |
|------------|-----------------------------------|
| `image_id` | ID of the pulled/built image     |

## Note

A build runs via `buildx` over SSH on the target host — this opens several parallel
SSH connections. See the [README](../../../README.md#why--parallelism1) for the
`-parallelism=1` note if this runs into a UFW SSH rate limit.
