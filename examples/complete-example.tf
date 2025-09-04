# Ejemplo completo con versión de aplicación, template de configuración y load balancer
module "elastic_beanstalk_complete" {
  source = "../"

  # Aplicación
  application_name        = "my-complete-app"
  application_description = "Mi aplicación completa con todas las características"

  # Lifecycle de versiones de aplicación
  appversion_lifecycle = {
    service_role          = "arn:aws:iam::123456789012:role/aws-elasticbeanstalk-service-role"
    max_count             = 10
    max_age_in_days       = 30
    delete_source_from_s3 = true
  }

  # Versión de aplicación
  create_application_version      = true
  application_version            = "v1.2.3"
  application_version_description = "Versión con nuevas características"
  source_bundle_bucket           = "my-app-deployments"
  source_bundle_key              = "releases/v1.2.3/app.zip"

  # Template de configuración
  create_configuration_template      = true
  configuration_template_name        = "my-app-config-template"
  configuration_template_description = "Template de configuración para producción"
  solution_stack_name               = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"

  configuration_settings = [
    # Configuración de instancias
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.medium,t3.large"
    },
    # Auto Scaling
    {
      namespace = "aws:autoscaling:asg"
      name      = "MinSize"
      value     = "2"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = "10"
    },
    # Load Balancer
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "LoadBalanced"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = "application"
    },
    # Health checks
    {
      namespace = "aws:elasticbeanstalk:healthreporting:system"
      name      = "SystemType"
      value     = "enhanced"
    },
    # Logs
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "StreamLogs"
      value     = "true"
    },
    {
      namespace = "aws:elasticbeanstalk:cloudwatch:logs"
      name      = "DeleteOnTerminate"
      value     = "false"
    }
  ]

  # Ambiente
  environment_name        = "my-complete-app-prod"
  environment_description = "Ambiente de producción con load balancer"

  # Configuraciones específicas del ambiente (pueden sobrescribir las del template)
  environment_settings = [
    # Variables de aplicación
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "ENVIRONMENT"
      value     = "production"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "DEBUG"
      value     = "false"
    },
    # Configuración de red
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = "vpc-12345678"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = "subnet-12345678,subnet-87654321"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = "subnet-12345678,subnet-87654321"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-complete-app"
    Owner       = "team-devops"
    CostCenter  = "engineering"
  }
}

# Outputs
output "application_name" {
  value = module.elastic_beanstalk_complete.application_name
}

output "application_version" {
  value = module.elastic_beanstalk_complete.application_version_name
}

output "environment_url" {
  value = module.elastic_beanstalk_complete.environment_endpoint_url
}

output "environment_cname" {
  value = module.elastic_beanstalk_complete.environment_cname
}

output "load_balancers" {
  value = module.elastic_beanstalk_complete.environment_load_balancers
}
