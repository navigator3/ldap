resource "google_compute_instance" "default" {
  name         = "ldap-${var.createway}"
  machine_type = "${var.machinetype}"
  zone         = "${var.zone}"
  description  = "create ldap"
  tags         = ["ldap"]
  metadata = {
    ssh-keys = "cmetaha17:${file("id_rsa.pub")}"
  }
  #    tags = var.tags
  #    labels = var.labels
  #metadata_startup_script = <<EFO
  #EFO
  metadata_startup_script = templatefile("startup.sh", {
    name          = "Sergei"
    surname       = "Shevtsov"
    your_password = "simpl_pass"
  })

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.hdd-size}"
      type  = "${var.hdd-type}"
    }

  }
  #provisioner "file" {
  #  source      = "scripts/"
  #  destination = "/home/"
  #}
  network_interface {
    #  count      = "${var.network-name}" == "default" ? 0 : 1
    network    = "${var.network-name}"
    subnetwork = "${var.sub-network-name}"
    access_config {
      // Ephemeral IP
    }
  }
}
