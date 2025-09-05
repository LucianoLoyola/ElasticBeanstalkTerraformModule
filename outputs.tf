# Application outputs
output "application_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.this.name
}

output "application_arn" {
  description = "ARN of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.this.arn
}

# Application Version outputs
output "application_version_arn" {
  description = "ARN of the Elastic Beanstalk application version"
  value       = var.create_application_version ? aws_elastic_beanstalk_application_version.this[0].arn : null
}

output "application_version_name" {
  description = "Name of the Elastic Beanstalk application version"
  value       = var.create_application_version ? aws_elastic_beanstalk_application_version.this[0].name : null
}

# Configuration Template outputs
output "configuration_template_name" {
  description = "Name of the Elastic Beanstalk configuration template"
  value       = var.create_configuration_template ? aws_elastic_beanstalk_configuration_template.this[0].name : null
}

# Environment outputs
output "environment_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.id
}

output "environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.name
}

output "environment_arn" {
  description = "ARN of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.arn
}

output "environment_application" {
  description = "Application associated with the environment"
  value       = aws_elastic_beanstalk_environment.this.application
}

output "environment_cname" {
  description = "CNAME of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.cname
}

output "environment_endpoint_url" {
  description = "Endpoint URL of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.endpoint_url
}

output "environment_instances" {
  description = "Instances used by the environment"
  value       = aws_elastic_beanstalk_environment.this.instances
}

output "environment_load_balancers" {
  description = "Load balancers used by the environment"
  value       = aws_elastic_beanstalk_environment.this.load_balancers
}

output "environment_autoscaling_groups" {
  description = "Autoscaling groups used by the environment"
  value       = aws_elastic_beanstalk_environment.this.autoscaling_groups
}

output "environment_launch_configurations" {
  description = "Launch configurations used by the environment"
  value       = aws_elastic_beanstalk_environment.this.launch_configurations
}

output "environment_queues" {
  description = "SQS queues used by the environment"
  value       = aws_elastic_beanstalk_environment.this.queues
}

output "environment_triggers" {
  description = "Autoscaling triggers used by the environment"
  value       = aws_elastic_beanstalk_environment.this.triggers
}

output "environment_platform_arn" {
  description = "Platform ARN of the environment"
  value       = aws_elastic_beanstalk_environment.this.platform_arn
}

output "environment_solution_stack_name" {
  description = "Solution stack name used by the environment"
  value       = aws_elastic_beanstalk_environment.this.solution_stack_name
}

output "environment_tier" {
  description = "Tier of the environment"
  value       = aws_elastic_beanstalk_environment.this.tier
}

output "environment_version_label" {
  description = "Version label of the environment"
  value       = aws_elastic_beanstalk_environment.this.version_label
}

# ==============================================================================
# IAM ROLES OUTPUTS
# ==============================================================================

output "service_role_arn" {
  description = "ARN of the Elastic Beanstalk service role"
  value       = var.create_iam_roles ? aws_iam_role.beanstalk_service_role[0].arn : null
}

output "service_role_name" {
  description = "Name of the Elastic Beanstalk service role"
  value       = var.create_iam_roles ? aws_iam_role.beanstalk_service_role[0].name : null
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = var.create_iam_roles ? aws_iam_role.beanstalk_ec2_role[0].arn : null
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance role"
  value       = var.create_iam_roles ? aws_iam_role.beanstalk_ec2_role[0].name : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = var.create_iam_roles ? aws_iam_instance_profile.beanstalk_ec2_profile[0].arn : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = var.create_iam_roles ? aws_iam_instance_profile.beanstalk_ec2_profile[0].name : null
}

# Custom IAM Policies Outputs
output "service_role_custom_policies" {
  description = "Names of custom inline policies attached to the service role"
  value       = var.create_iam_roles ? [for policy in aws_iam_role_policy.service_role_custom : policy.name] : []
}

output "service_role_custom_managed_policies" {
  description = "ARNs of custom managed policies attached to the service role"
  value       = var.service_role_custom_managed_policies
}

output "ec2_instance_role_custom_policies" {
  description = "Names of custom inline policies attached to the EC2 instance role"
  value       = var.create_iam_roles ? [for policy in aws_iam_role_policy.ec2_instance_role_custom : policy.name] : []
}

output "ec2_instance_role_custom_managed_policies" {
  description = "ARNs of custom managed policies attached to the EC2 instance role"
  value       = var.ec2_instance_role_custom_managed_policies
}
