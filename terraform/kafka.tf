data "template_file" "kafka_startup_script" {
  template = "${file("../tools/config/kafka.conf")}"
  vars {
    kafka_version = "${var.kafka_version}"
    zk1_ip        = "${google_compute_address.zk_int_address.0.address}"
    zk2_ip        = "${google_compute_address.zk_int_address.1.address}"
    zk3_ip        = "${google_compute_address.zk_int_address.2.address}"
    kafka_log_dir = "${var.kafka_log_dir}"
  }
}

resource "google_compute_instance" "kafka" {
  depends_on   = ["google_compute_instance.zk"]
  count        = "${var.kafka_node_count}"
  name         = "kafka${count.index + 1}"
  machine_type = "${var.kafka_machine_type}"
  zone         = "${var.zone}"
  tags         = ["${module.nat.routing_tag_regional}", "${module.nat.routing_tag_zonal}"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.test_subnet_priv.name}"
  }

  metadata_startup_script = "${data.template_file.kafka_startup_script.rendered}"
}
