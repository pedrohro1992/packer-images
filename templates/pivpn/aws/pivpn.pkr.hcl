packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "pivpn-base-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  
  ssh_username = "ubuntu"

  tags = {
    Name = "pivpn-base"
  }
}

build {
  name = "pivpn-build"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "file" {
    source      = "options.conf"
    destination = "/home/ubuntu/options.conf"
  }

  provisioner "shell" {
    inline = [
      "echo 'Update the system'",
      "sudo add-apt-repository universe -y",
      "sudo apt-get update -y",
      "sudo apt-get install -y git curl",

      "echo 'Create instalation dir'",
      "sudo mkdir -p /usr/local/src/pivpn",
      "sudo chown -R ubuntu:ubuntu /usr/local/src/pivpn",

      "echo 'Download and Install PiVPN'",
      "curl -L https://install.pivpn.io > install.sh",
      "chmod +x install.sh",
      "sudo ./install.sh --unattended /home/ubuntu/options.conf",
      "rm install.sh"
    ]
  }
}
