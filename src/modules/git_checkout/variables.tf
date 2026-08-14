variable "repo_url" {
  type        = string
  description = "Git-Repository-URL, die geklont wird"
}

variable "ref" {
  type        = string
  description = "Git-Tag oder Commit-SHA, auf den ausgecheckt wird"
}

variable "checkout_dir" {
  type        = string
  description = "Lokales Verzeichnis, in das geklont wird (wird bei jedem Apply neu angelegt)"
}
