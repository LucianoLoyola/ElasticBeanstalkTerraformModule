# Uso con Terragrunt

Este módulo está optimizado para ser usado con Terragrunt. Aquí tienes ejemplos de configuración:

## Estructura Recomendada

```
project/
├── terragrunt.hcl (configuración raíz)
├── modules/
│   └── elastic-beanstalk/ (este módulo)
└── environments/
    ├── dev/
    │   └── app/
    │       └── terragrunt.hcl
    ├── staging/
    │   └── app/
    │       └── terragrunt.hcl
    └── prod/
        └── app/
            └── terragrunt.hcl
```

## Ejemplo Básico - Desarrollo

```hcl
# environments/dev/app/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/elastic-beanstalk"
}

inputs = {
  application_name = "mi-app"
  environment_name = "mi-app-dev"
  
  solution_stack_name = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"
  
  environment_settings = [
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.micro"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "SingleInstance"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "ENVIRONMENT"
      value     = "development"
    }
  ]
  
  tags = {
    Environment = "development"
    Project     = "mi-app"
    CostCenter  = "development"
  }
}
```

## Ejemplo Completo - Producción

```hcl
# environments/prod/app/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/elastic-beanstalk"
}

inputs = {
  application_name = "mi-app"
  environment_name = "mi-app-prod"
  
  # Crear versión de aplicación desde S3
  create_application_version = true
  application_version = "v1.0.0"
  source_bundle_bucket = "mi-app-deployments"
  source_bundle_key = "releases/v1.0.0/app.zip"
  
  solution_stack_name = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"
  
  environment_settings = [
    # Instancias
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.medium,t3.large"
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
    # Networking
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
    # Environment Variables
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "ENVIRONMENT"
      value     = "production"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "DEBUG"
      value     = "false"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "mi-app"
    CostCenter  = "production"
  }
}
```

## Ejemplo Worker

```hcl
# environments/prod/worker/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/elastic-beanstalk"
}

inputs = {
  application_name = "mi-app-worker"
  environment_name = "mi-app-worker-prod"
  environment_tier = "Worker"
  
  solution_stack_name = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"
  
  environment_settings = [
    # Worker Configuration
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "WorkerQueueURL"
      value     = "https://sqs.us-east-1.amazonaws.com/123456789012/my-queue"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "HttpPath"
      value     = "/worker"
    },
    # Instance Configuration
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.small"
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
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "mi-app-worker"
    Type        = "worker"
  }
}
```

## Comandos Terragrunt

```bash
# Planificar cambios
terragrunt plan

# Aplicar cambios
terragrunt apply

# Destruir recursos
terragrunt destroy

# Validar configuración
terragrunt validate

# Ver outputs
terragrunt output
```

## Variables Comunes

Puedes usar el archivo `terragrunt.hcl` raíz para definir variables comunes:

```hcl
# terragrunt.hcl (raíz)
remote_state {
  backend = "s3"
  config = {
    bucket = "mi-terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
  }
}

inputs = {
  aws_region = "us-east-1"
  
  common_tags = {
    ManagedBy   = "terragrunt"
    Owner       = "devops-team"
    Project     = "mi-proyecto"
  }
}
```
