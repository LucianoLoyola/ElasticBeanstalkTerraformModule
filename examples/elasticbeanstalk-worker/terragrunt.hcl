# environments/staging/worker/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../ElasticBeanstalkModule"
}

inputs = {
  application_name = "express-demo-app-worker"
  environment_name = "express-demo-app-worker"
  
  # Configurar como Worker tier
  environment_tier = "Worker"
  
  # Crear roles IAM automáticamente
  create_iam_roles = true
  service_role_name = "express-demo-app-worker-service-role"
  ec2_instance_role_name = "express-demo-app-worker-ec2-role"
  
  # Crear versión de aplicación desde S3
  create_application_version = true
  application_version = "v1.0.4-worker"
  source_bundle_bucket = "express-demo-app"
  source_bundle_key = "expressworkerdemoapp-20250904-203954.zip"
  
  #aws elasticbeanstalk list-available-solution-stacks
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  # Configuración de red
  vpc_id = "vpc-0f6a5bbd2546359df"
  ec2_subnets = ["subnet-03ce92dba629183ee", "subnet-0c782c7059d7ac402", "subnet-00bebdf8f9e7ce1b9"]
  
  # Configuración de instancias
  instance_types = ["t3.micro"]
  
  # === GESTIÓN DE COLA SQS ===
  # Opción 1: Crear cola SQS automáticamente
  create_sqs_queue = true
  sqs_queue_name = "express-demo-app-worker-queue-v2"
  
  # Configuración opcional de la cola
  sqs_queue_visibility_timeout_seconds = 300
  sqs_queue_message_retention_seconds = 345600  # 4 days
  sqs_queue_receive_wait_time_seconds = 10
  
  # Dead Letter Queue opcional
  sqs_dlq_enabled = true
  sqs_dlq_max_receive_count = 3
  
  # Opción 2: Usar cola existente (deshabilitado)
  # worker_queue_url = "https://sqs.us-west-2.amazonaws.com/600627334574/express-demo-app-worker-queue"
  
  # Configuración específica del Worker
  worker_http_path = "/worker"
  worker_mime_type = "application/json"
  worker_http_connections = 10
  worker_connect_timeout = 5
  worker_inactivity_timeout = 299
  worker_visibility_timeout = 300
  worker_retention_period = 345600
  
  # Variables de entorno de la aplicación
  application_environment_variables = {
    NODE_ENV = "development"
    PORT = "8080"
    ENVIRONMENT = "worker"
    WORKER_MODE = "true"
    DEBUG = "false"
  }
  
  # Políticas IAM personalizadas para el service role
  service_role_custom_policies = [
    {
      name   = "WorkerServiceMonitoring"
      policy = file("${get_terragrunt_dir()}/policies/worker-service-monitoring.json")
    }
  ]
  
  # Políticas managed adicionales para el service role
  service_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
  ]
  
  # Políticas IAM personalizadas cargadas desde archivos externos
  ec2_instance_role_custom_policies = [
    {
      name   = "WorkerSQSFullAccess"
      policy = file("${get_terragrunt_dir()}/policies/worker-sqs-access.json")
    },
    {
      name   = "DatabaseAccess"
      policy = file("${get_terragrunt_dir()}/policies/database-access.json")
    }
  ]
  
  # Políticas managed adicionales para monitoreo
  ec2_instance_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  
  #=== CONFIGURACIÓN DE SECURITY GROUPS ===
  #Crear security groups personalizados
  create_security_groups = true
  security_group_name = "express-demo-app-worker-sg"
  security_group_description = "Security group for Express Demo App worker environment"
  
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
  
  #Configuraciones adicionales específicas 
  environment_settings = []
  
  tags = {
    Environment = "staging"
    Project     = "express-demo-app"
    Type        = "worker"
  }
}