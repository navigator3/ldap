provider "google" {
  #credentials = "${file("terraform-admin.json")}"
  project = "${var.projectname}"
  region  = "${var.region}"
}
