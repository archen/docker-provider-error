terraform {
  required_providers {
    aws = {
      version = ">=3.60.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "docker" {
  registry_auth {
    address     = "${local.ecr}"
    config_file = "${path.module}/resources/docker-config.json"
  }
}

locals {
  ecr = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

variable "images" {
  type    = set(string)
  default = ["broke-registry", "works-root", "works-chmod"]
}

resource "docker_image" "local" {
  for_each = var.images
  name     = "test-docker-image"

  build {
    path       = "resources/build_context"
    dockerfile = "dockerfile-${each.value}"
    tag        = ["test-docker-image:${each.value}"]
  }
}

resource "aws_ecr_repository" "ecr" {
  name = "test-registry-image"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "docker_registry_image" "image_sync" {
  for_each = var.images
  name     = "${local.ecr}/${aws_ecr_repository.ecr.name}:${each.value}"

  build {
    context    = "resources/build_context"
    dockerfile = "dockerfile-${each.value}"
  }
}
