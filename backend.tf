terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    bucket  = "terrafrombk89"
    key     = "terrafmstatef"
    region  = "us-east-1"
    profile = "default"
  }
}
