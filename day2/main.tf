resource "google_compute_network" "ldap_network" {
  name                    = "${var.network-name}"
  auto_create_subnetworks = false
  description             = "create VPC"
}

resource "google_compute_subnetwork" "ldap_sub_net" {
  name          = "${var.ldap-sub-net-name}"
  ip_cidr_range = "${var.ldap-sub-net-ip-range}"
  region        = "${var.region}"
  network       = google_compute_network.ldap_network.id
  depends_on    = [google_compute_network.ldap_network, ]
  description   = "create subnetwork"
}
resource "google_compute_firewall" "ldap_firewall_web" {
  name        = "ldap-firewall-web"
  network     = google_compute_network.ldap_network.name
  target_tags = ["ldap-web"]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = "${var.web-port}"
  }
  allow {
    protocol = "udp"
    ports    = "${var.web-port}"
  }
  source_ranges = ["0.0.0.0/0"]
  description   = "create firewall web rules for 80,22 ports"
}


resource "google_compute_instance" "default" {
  name         = "ldap-${var.createway}"
  machine_type = "${var.machinetype}"
  zone         = "${var.zone}"
  description  = "create ldap"
  tags         = ["ldap-web"]
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
    network    = google_compute_network.ldap_network.name    #"${var.network-name}"
    subnetwork = google_compute_subnetwork.ldap_sub_net.name #"${var.sub-network-name}"
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "ldap_cli" {
  count        = 1
  name         = "ldap-cli-${var.createway}"
  machine_type = "${var.machinetype}"
  zone         = "${var.zone}"
  description  = "create ldap clients"
  tags         = ["ldap-web"]
  metadata = {
    ssh-keys = "cmetaha17:${file("id_rsa.pub")}"
  }
  #    tags = var.tags
  #    labels = var.labels
  #metadata_startup_script = <<EFO
  #EFO
  metadata_startup_script = templatefile("startup-cli.sh", {
    name         = "Sergei"
    surname      = "Shevtsov"
    ip_ldap_serv = google_compute_instance.default.network_interface.0.network_ip
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
    network    = google_compute_network.ldap_network.name    #"${var.network-name}"
    subnetwork = google_compute_subnetwork.ldap_sub_net.name #"${var.sub-network-name}"
    access_config {
      // Ephemeral IP
    }
  }
}
