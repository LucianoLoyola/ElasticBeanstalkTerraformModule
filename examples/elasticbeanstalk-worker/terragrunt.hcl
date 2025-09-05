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
  
  environment_settings = [
    # Instancias
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.micro"
    },
    # Configuración SQS Worker
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "WorkerQueueURL"
      value     = "https://sqs.us-west-2.amazonaws.com/600627334574/express-demo-app-worker-queue"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "HttpPath"
      value     = "/worker"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "MimeType"
      value     = "application/json"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "HttpConnections"
      value     = "10"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "ConnectTimeout"
      value     = "5"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "InactivityTimeout"
      value     = "299"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "VisibilityTimeout"
      value     = "300"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "RetentionPeriod"
      value     = "345600"
    },
    # Networking
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = "vpc-0f6a5bbd2546359df"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = "subnet-03ce92dba629183ee,subnet-0c782c7059d7ac402,subnet-00bebdf8f9e7ce1b9"
    },
    # Environment Variables para Worker
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "NODE_ENV"
      value     = "development"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "PORT"
      value     = "8080"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "ENVIRONMENT"
      value     = "worker"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "WORKER_MODE"
      value     = "true"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "DEBUG"
      value     = "false"
    }
  ]
  
  tags = {
    Environment = "staging"
    Project     = "express-demo-app"
    Type        = "worker"
  }
}