# Ejemplo para ambiente Worker (para procesamiento de colas)
module "elastic_beanstalk_worker" {
  source = "../"

  # Aplicación
  application_name        = "my-worker-app"
  application_description = "Aplicación worker para procesamiento de background jobs"

  # Ambiente Worker
  environment_name        = "my-worker-app-prod"
  environment_description = "Worker para procesamiento de tareas"
  environment_tier        = "Worker"
  solution_stack_name     = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"

  # Configuraciones específicas para Worker
  environment_settings = [
    # Configuración de Worker
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "WorkerQueueURL"
      value     = "https://sqs.us-east-1.amazonaws.com/123456789012/my-work-queue"
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
      value     = "300"
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
    # Configuración de instancias
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.medium"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MinSize"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = "5"
    },
    # Variables de aplicación
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "WORKER_MODE"
      value     = "true"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "LOG_LEVEL"
      value     = "INFO"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-worker-app"
    Type        = "worker"
    Owner       = "team-backend"
  }
}

# Outputs
output "worker_application_name" {
  value = module.elastic_beanstalk_worker.application_name
}

output "worker_environment_name" {
  value = module.elastic_beanstalk_worker.environment_name
}

output "worker_queues" {
  value = module.elastic_beanstalk_worker.environment_queues
}
