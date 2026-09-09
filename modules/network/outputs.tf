output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs keyed by index"
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "app_subnet_ids" {
  description = "Map of private app subnet IDs keyed by index"
  value       = { for k, s in aws_subnet.app : k => s.id }
}

output "db_subnet_ids" {
  description = "Map of private db subnet IDs keyed by index"
  value       = { for k, s in aws_subnet.db : k => s.id }
}

output "public_subnet_ids_list" {
  description = "Flat list of public subnet IDs (convenient for ALB module)"
  value       = values(aws_subnet.public)[*].id
}

output "app_subnet_ids_list" {
  description = "Flat list of app subnet IDs (convenient for ASG module)"
  value       = values(aws_subnet.app)[*].id
}

output "db_subnet_ids_list" {
  description = "Flat list of db subnet IDs (convenient for RDS subnet group)"
  value       = values(aws_subnet.db)[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by AZ"
  value       = { for k, n in aws_nat_gateway.this : k => n.id }
}

output "availability_zones_used" {
  description = "List of AZs actually used"
  value       = local.azs
}