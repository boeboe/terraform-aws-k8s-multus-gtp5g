terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.67"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
  }

  required_version = "~> 1.0"
}