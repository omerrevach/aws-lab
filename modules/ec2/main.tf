resource "aws_instance" "linux_ec2" {
  ami = var.linux_ami
  instance_type = var.instance_type
  subnet_id = var.private_subnets[0]
  iam_instance_profile = var.iam_instance_profile // To connect to an EC2 instance using SSM

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y unzip curl git
              curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/${var.k8s_version}/${var.k8s_build}/bin/linux/amd64/kubectl
              chmod +x kubectl
              mv kubectl /usr/local/bin
              curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
              EOF
  
  tags = {
    Name = var.linux_name
  }
}


resource "aws_instance" "windows_ec2" {
  ami                  = var.windows_ami
  instance_type        = var.instance_type
  subnet_id            = var.private_subnets[1]
  iam_instance_profile = var.iam_instance_profile

  tags = {
    Name = var.windows_name
  }
}