terraform {
  backend "gcs" {
    bucket = "terraform-admin-sdggwo3r"
    prefix = "terraform/state"
  }
}
