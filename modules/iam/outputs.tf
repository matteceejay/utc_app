output "instance_profile_name" {
  value = aws_iam_instance_profile.app_instance.name
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.app_instance.arn
}

output "role_name" {
  value = aws_iam_role.app_instance.name
}

output "role_arn" {
  value = aws_iam_role.app_instance.arn
}