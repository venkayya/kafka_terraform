data "template_file" "kerberos_startup_script" {
  template = "${file("../config/kerberos.sh")}"

}

resource "google_compute_instance" "kerberos" {
  name         = "kerberos"
  machine_type = "${var.kerberos_machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      #image = "ubuntu-os-cloud/ubuntu-1804-lts"
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.test_subnet_priv.name}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${data.template_file.kerberos_startup_script.rendered}"
}
