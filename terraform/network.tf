resource "google_compute_network" "test_net_priv" {
  name                    = "test"
  auto_create_subnetworks = false
  project                 = "${var.project}"
}

resource "google_compute_subnetwork" "test_subnet_priv" {
  name                     = "kafka-zk-net"
  project                  = "${var.project}"
  region                   = "${var.region}"
  private_ip_google_access = true
  ip_cidr_range            = "10.0.0.0/24"
  network                  = "${google_compute_network.test_net_priv.self_link}"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "all"
    #ports    = ["1281", "2888", "3888", "22"]
  }

  source_ranges = ["10.0.0.0/24"]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "prometheus" {
  name    = "prometheus"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "grafana" {
  name    = "grafana"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "jolokia" {
  name    = "jolokia"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["8778"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "kafka_monitor" {
  name    = "kafka-monitor"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "kafka_manager" {
  name    = "kafka-manager"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "zoo_navigator_web" {
  name    = "zoo-navigator-web"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["7070"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "zoo_navigator_api" {
  name    = "zoo-navigator-api"
  network = "${google_compute_network.test_net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["7072"]
  }

  source_ranges = ["0.0.0.0/0"]
}

module "nat" {
  source        = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  project       = "${var.project}"
  region        = "${var.region}"
  zone          = "${var.zone}"
  tags          = ["test-nat"]
  network       = "${google_compute_network.test_net_priv.name}"
  subnetwork    = "${google_compute_subnetwork.test_subnet_priv.name}"
  compute_image = "projects/debian-cloud/global/images/family/debian-9"
}
