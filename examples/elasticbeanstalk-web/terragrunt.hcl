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
  
  #Crear IAM roles automáticamente
  create_iam_roles = true
  service_role_name = "express-demo-app-service-role"
  ec2_instance_role_name = "express-demo-app-ec2-role"
  
  #Crear versión de aplicación desde S3
  create_application_version = true
  application_version = "v1.0.2"
  source_bundle_bucket = "express-demo-app"
  source_bundle_key = "expressdemoapp-clean-20250903-225344.zip"
  
  #aws elasticbeanstalk list-available-solution-stacks
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  #Configuración simplificada del entorno
  environment_type = "LoadBalanced"
  load_balancer_type = "application"
  
  #Configuración de red
  vpc_id = "vpc-0f6a5bbd2546359df"
  ec2_subnets = ["subnet-03ce92dba629183ee", "subnet-0c782c7059d7ac402", "subnet-00bebdf8f9e7ce1b9"]
  elb_subnets = ["subnet-094c810dd8345c3b5", "subnet-0692800804ab0688f", "subnet-0497427b04eaef497"]
  
  #Configuración de instancias
  instance_types = ["t3.micro"]
  auto_scaling_min_size = 1
  auto_scaling_max_size = 1
  
  #Configuración de health check
  health_check_path = "/health"
  health_check_interval = 30
  health_check_timeout = 5
  healthy_threshold_count = 2
  unhealthy_threshold_count = 3
  health_check_http_code = "200"
  
  #Variables de entorno de la aplicación
  application_environment_variables = {
    NODE_ENV = "development"
    PORT = "8080"
    ENVIRONMENT = "development"
    DEBUG = "false"
  }
  
  #IAM Policies personalizadas para el service role
  service_role_custom_policies = [
    {
      name   = "ServiceEnhancedMonitoring"
      policy = file("${get_terragrunt_dir()}/policies/service-enhanced-monitoring.json")
    }
  ]
  
  #Managed IAM Policies adicionales para el service role
  service_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
  ]
  
  #IAM Policies personalizadas para el ec2-instance-role
  ec2_instance_role_custom_policies = [
    {
      name   = "WebMonitoringAccess"
      policy = file("${get_terragrunt_dir()}/policies/web-monitoring-access.json")
    },
    {
      name   = "WebEmailConfigAccess"
      policy = file("${get_terragrunt_dir()}/policies/web-email-config-access.json")
    }
  ]
  
  #Managed IAM Policies adicionales para el ec2-instance-role
  ec2_instance_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
  
  #=== CONFIGURACIÓN DE SECURITY GROUPS ===
  #Crear security groups personalizados
  create_security_groups = true
  security_group_name = "express-demo-app-web-sg"
  security_group_description = "Security group for Express Demo App web environment"
  
  #Reglas de ingreso personalizadas
  security_group_ingress_rules = [
    {
      description = "HTTP access from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    },
    {
      description = "HTTPS access from ALB"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    },
    {
      description = "SSH access for debugging"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]  # Solo desde la VPC
    },
    {
      description = "Application port"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
  
  #Reglas de egreso (por defecto permite todo el tráfico saliente)
  security_group_egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  
  #Security groups adicionales (si los necesitas)
  #additional_security_group_ids = ["sg-xxxxxxxxx"]
  
  #Configuraciones adicionales específicas (si es necesario)
  environment_settings = []
  
  tags = {
    Environment = "development"
    Project     = "express-demo-app"
  }
}