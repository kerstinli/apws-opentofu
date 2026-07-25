# docker_image

Pullt ein Docker-Image, oder baut es (wenn `build_context` gesetzt ist), auf dem via
`docker`-Provider konfigurierten Zielhost.

## Beispiel

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
}
```

## Inputs

| Name               | Beschreibung                                                              | Typ      | Default          |
|--------------------|----------------------------------------------------------------------------|----------|------------------|
| `name`             | Image-Name inkl. Tag (z. B. `opensearchproject/opensearch:3.7.0`)          | `string` | –                |
| `platform`         | Zielplattform                                                              | `string` | `"linux/arm64"`  |
| `keep_locally`     | Image beim Destroy lokal behalten                                          | `bool`   | `true`           |
| `build_context`    | Pfad zum Build-Context. Wenn gesetzt, wird gebaut statt gepullt            | `string` | `null`           |
| `build_dockerfile` | Dockerfile-Name relativ zu `build_context`                                 | `string` | `"Dockerfile"`   |

## Outputs

| Name       | Beschreibung                     |
|------------|-----------------------------------|
| `image_id` | ID des gepullten/gebauten Images |

## Hinweis

Ein Build läuft über `buildx` per SSH auf dem Zielhost — das öffnet mehrere parallele
SSH-Verbindungen. Siehe [README](../../../README.md#warum--parallelism1) zum
`-parallelism=1`-Hinweis, falls das an einem UFW-SSH-Rate-Limit scheitert.
