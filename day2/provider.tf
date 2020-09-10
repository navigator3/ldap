provider "google" {
  #credentials = "${file("/home/terraform-admin.json")}"
  project = "${var.projectname}"
  region  = "${var.region}"
}
