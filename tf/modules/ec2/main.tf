resource "aws_instance" "linux_ec2" {
  ami                    = var.linux_ami
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets[0]
  iam_instance_profile   = var.iam_instance_profile
  vpc_security_group_ids = [aws_security_group.linux_ec2_sg.id]

  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y curl git jq unzip
        # Install kubectl (v1.31.0 to match EKS)
        curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl
        chmod +x kubectl
        mv kubectl /usr/local/bin/
        # Install AWS CLI v2 (latest)
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        # Install Helm
        curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
        # Configure kubeconfig for ssm-user
        mkdir -p /home/ssm-user/.kube
        export AWS_REGION=${var.aws_region}
        aws eks update-kubeconfig --region ${var.aws_region} --name ${var.eks_cluster_name} --kubeconfig /home/ssm-user/.kube/config
        chown -R ssm-user:ssm-user /home/ssm-user/.kube
        chmod 600 /home/ssm-user/.kube/config
        # Configure kubeconfig for ec2-user
        mkdir -p /home/ec2-user/.kube
        cp /home/ssm-user/.kube/config /home/ec2-user/.kube/config
        chown -R ec2-user:ec2-user /home/ec2-user/.kube
        chmod 600 /home/ec2-user/.kube/config
        EOF

  tags = {
    Name = var.linux_name
  }
}


resource "aws_security_group" "linux_ec2_sg" {
  name   = "linux-ec2-sg"
  vpc_id = var.vpc_id
  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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