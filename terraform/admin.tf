resource "google_compute_instance" "kf_zk_monitor" {
  depends_on   = ["google_compute_instance.kafka"]
  name         = "adminbox1"
  machine_type = "${var.admin_machine_type}"
  zone         = "${var.zone}"
  tags         = ["monitoring"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.test_subnet_priv.name}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${data.template_file.prom_startup_script.rendered}"
}

data "template_file" "prom_startup_script" {
  template = "${file("../tools/config/admin.conf")}"

  vars{
    DOCKER_URL="https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64"
  }
}
