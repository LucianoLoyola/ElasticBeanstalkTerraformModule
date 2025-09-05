# environments/prod/app/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../ElasticBeanstalkModule"
}

inputs = {
  application_name = "express-demo-app"
  environment_name = "express-demo-app-dev"
  
  # Crear roles IAM automáticamente
  create_iam_roles = true
  service_role_name = "express-demo-app-service-role"
  ec2_instance_role_name = "express-demo-app-ec2-role"
  
  # Crear versión de aplicación desde S3
  create_application_version = true
  application_version = "v1.0.2"
  source_bundle_bucket = "express-demo-app"
  source_bundle_key = "expressdemoapp-clean-20250903-225344.zip"
  
  #aws elasticbeanstalk list-available-solution-stacks
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  # Configuración simplificada del entorno
  environment_type = "LoadBalanced"
  load_balancer_type = "application"
  
  # Configuración de red
  vpc_id = "vpc-0f6a5bbd2546359df"
  ec2_subnets = ["subnet-03ce92dba629183ee", "subnet-0c782c7059d7ac402", "subnet-00bebdf8f9e7ce1b9"]
  elb_subnets = ["subnet-094c810dd8345c3b5", "subnet-0692800804ab0688f", "subnet-0497427b04eaef497"]
  
  # Configuración de instancias
  instance_types = ["t3.micro"]
  auto_scaling_min_size = 1
  auto_scaling_max_size = 1
  
  # Configuración de health check
  health_check_path = "/health"
  health_check_interval = 30
  health_check_timeout = 5
  healthy_threshold_count = 2
  unhealthy_threshold_count = 3
  health_check_http_code = "200"
  
  # Variables de entorno de la aplicación
  application_environment_variables = {
    NODE_ENV = "development"
    PORT = "8080"
    ENVIRONMENT = "development"
    DEBUG = "false"
  }
  
  # Configuraciones adicionales específicas (si es necesario)
  environment_settings = []
  
  tags = {
    Environment = "development"
    Project     = "express-demo-app"
  }
}