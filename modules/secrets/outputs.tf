output "secret_arn" {
  description = "ARN of the app secret - pass this to the app as an env var, never the secret value itself"
  value       = aws_secretsmanager_secret.app.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}