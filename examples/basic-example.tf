# Ejemplo básico de Elastic Beanstalk con aplicación simple
module "elastic_beanstalk_basic" {
  source = "../"

  # Aplicación
  application_name        = "my-web-app"
  application_description = "Mi aplicación web básica"

  # Ambiente
  environment_name        = "my-web-app-prod"
  environment_description = "Ambiente de producción"
  solution_stack_name     = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"

  # Configuraciones básicas del ambiente
  environment_settings = [
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.small"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "SingleInstance"
    },
    {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = "aws-elasticbeanstalk-ec2-role"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-web-app"
    Owner       = "team-devops"
  }
}

# Outputs
output "application_name" {
  value = module.elastic_beanstalk_basic.application_name
}

output "environment_url" {
  value = module.elastic_beanstalk_basic.environment_endpoint_url
}

output "environment_cname" {
  value = module.elastic_beanstalk_basic.environment_cname
}
