terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.4.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.4.0"
    }
  }
}