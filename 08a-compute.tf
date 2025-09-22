# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

#  - Balerica - Singapore - asian-southeast1-a
resource "google_compute_instance" "balerica-vm" {
  provider     = google.balerica
  name         = "balerica-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone1

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.balerica_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup/startup.sh")
}



#  - Taa - Toronto - northamerica-northeast1-a
resource "google_compute_instance" "genosha-vm" {
  provider     = google.genosha-ops
  name         = "genosha-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone2

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.genosha_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup/taastartup.sh")
}


/*

# TIQS - Sao Paulo - southamerica-east1-a
# Genosha
resource "google_compute_instance" "tiqs-vm" {
  provider     = google.genosha-ops
  name         = "tiqs-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone2


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tiqs-subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup/tiqs.sh")
}

*/

/*
#Genosha - South Africa - africa-south1-a
resource "google_compute_instance" "genosha-vm" {
  provider     = google.genosha-ops
  name         = "genosha-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone4


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.genosha-subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup/genosha-startup.sh")
}
*/



/*
# Tokyo - Taaops
resource "google_compute_instance" "tokyo-vm" {
  provider     = google.balerica
  name         = "tokyo-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone5


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tokyo-subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup/tokyo-startup.sh")
}
*/