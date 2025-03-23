output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  value = module.vpc.azs
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnet_cidrs" {
  value = module.vpc.private_subnet_cidrs
}

output "public_subnet_cidrs" {
  value = module.vpc.public_subnet_cidrs
}

output "nat_gateway_ids" {
  value = module.vpc.natgw_ids
}
