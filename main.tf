resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Allow inbound HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = "ami-0861f4e788f5069dd"
  instance_type = "t2.micro"
  key_name      = "terraform-minikube-key"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  tags = {
    Name = "WebServerInstance"
  }
}

resource "null_resource" "web_server_config" {
  triggers = {
    # This trigger will re-run the provisioner if the content of webserver.sh changes.
    file_content_hash = sha256(file("${path.module}/webserver.sh"))
    instance_id = aws_instance.web_server.id
  }

  # Copy the script to the EC2 instance
  provisioner "file" {
    source      = "webserver.sh"
    destination = "/tmp/webserver.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/terraform-minikube-key.pem")
      host        = aws_instance.web_server.public_ip
    }
  }

  # Execute the script on the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/webserver.sh",
      "sudo /tmp/webserver.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/terraform-minikube-key.pem")
      host        = aws_instance.web_server.public_ip
    }
  }
}
