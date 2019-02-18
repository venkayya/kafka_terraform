resource "google_compute_disk" "zk_data_disk" {
  count = "${var.zk_node_count}"
  name  = "zk${count.index + 1}-data-disk"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  size  = "${var.zk_disk_size}"
}

resource "google_compute_address" "zk_int_address" {
  count        = "${var.zk_node_count}"
  name         = "zk${count.index + 1}-address"
  subnetwork   = "${google_compute_subnetwork.test_subnet_priv.name}"
  address_type = "INTERNAL"
  region       = "${var.region}"
}

resource "google_compute_instance" "zk" {
  depends_on   = ["google_compute_instance.kerberos"]
  count        = "${var.zk_node_count}"
  name         = "zk${count.index + 1}"
  machine_type = "${var.zk_machine_type}"
  zone         = "${var.zone}"
  tags         = ["${module.nat.routing_tag_regional}", "${module.nat.routing_tag_zonal}"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.zk_data_disk.*.name, count.index)}"
    mode   = "READ_WRITE"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.test_subnet_priv.name}"
    network_ip = "${element(google_compute_address.zk_int_address.*.address, count.index)}"
  }

  metadata_startup_script = "${data.template_file.zk_startup_script.rendered}"
}

data "template_file" "zk_startup_script" {
  template = "${file("../config/zoo.sh")}"
  vars {
    zk_version    = "${var.zk_version}"
    zk1_ip        = "${google_compute_address.zk_int_address.0.address}"
    zk2_ip        = "${google_compute_address.zk_int_address.1.address}"
    zk3_ip        = "${google_compute_address.zk_int_address.2.address}"
    zkdata_dir    = "${var.zkdata_dir}"
  }
}
