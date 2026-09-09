output "s3_bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "efs_file_system_id" {
  value = aws_efs_file_system.uploads.id
}

output "efs_dns_name" {
  description = "Use this to mount: <dns_name>:/ or via the access point"
  value       = aws_efs_file_system.uploads.dns_name
}

output "efs_access_point_id" {
  value = aws_efs_access_point.uploads.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}



output "efs_file_system_arn" {
  value = aws_efs_file_system.uploads.arn
}

output "efs_access_point_arn" {
  value = aws_efs_access_point.uploads.arn
}