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
  
  # Configuración específica del Worker
  worker_queue_url = "https://sqs.us-west-2.amazonaws.com/600627334574/express-demo-app-worker-queue"
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
  
  # Configuraciones adicionales específicas (si es necesario)
  environment_settings = []
  
  tags = {
    Environment = "staging"
    Project     = "express-demo-app"
    Type        = "worker"
  }
}