output "linux_ec2_id" {
  value = aws_instance.linux_ec2.id
}

output "windows_ec2_id" {
  value = aws_instance.windows_ec2.id
}

output "linux_instance_name" {
  value = aws_instance.linux_ec2.tags["Name"]
}

output "windows_instance_name" {
  value = aws_instance.windows_ec2.tags["Name"]
}
