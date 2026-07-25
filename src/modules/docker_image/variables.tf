variable "name" {
  type        = string
  description = "Docker image name including tag (e.g. opensearchproject/opensearch:3.7.0)"
}

variable "platform" {
  type        = string
  description = "Target platform (e.g. linux/arm64)"
  default     = "linux/arm64"
}

variable "keep_locally" {
  type        = bool
  description = "Keep the image locally after the resource is destroyed"
  default     = true
}

variable "build_context" {
  type        = string
  description = "Path to the Docker build context. If set, the image will be built instead of pulled."
  default     = null
}

variable "build_dockerfile" {
  type        = string
  description = "Dockerfile name relative to build_context"
  default     = "Dockerfile"
}

variable "triggers" {
  type        = map(string)
  description = "Arbitrary map that forces a rebuild when changed (e.g. file hashes of the build context) — the provider does not detect build-context changes on its own"
  default     = {}
}

