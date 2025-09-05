# Módulo Terraform para AWS Elastic Beanstalk

Módulo de Terraform para desplegar aplicaciones en AWS Elastic Beanstalk. Compatible con Terragrunt.

## Características

- ✅ Aplicaciones Elastic Beanstalk
- ✅ Versiones de aplicaciones con S3
- ✅ Templates de configuración reutilizables
- ✅ Ambientes Web Server y Worker
- ✅ Auto-detección de solution stacks
- ✅ Soporte completo para configuraciones personalizadas

## Uso con Terragrunt

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/tu-repo/elastic-beanstalk-module.git?ref=v1.0.0"
}

inputs = {
  application_name = "mi-app"
  environment_name = "mi-app-prod"
  
  solution_stack_name = "64bit Amazon Linux 2 v3.4.24 running Python 3.8"
  
  environment_settings = [
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.medium"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "LoadBalanced"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "mi-app"
  }
}
```

## Variables Principales

| Variable | Descripción | Tipo | Requerido |
|----------|-------------|------|-----------|
| `application_name` | Nombre de la aplicación | `string` | ✅ |
| `environment_name` | Nombre del ambiente | `string` | ✅ |
| `solution_stack_name` | Solution stack (auto-detecta si es null) | `string` | ❌ |
| `environment_settings` | Configuraciones del ambiente | `list(object)` | ❌ |
| `environment_tier` | Tier del ambiente (WebServer/Worker) | `string` | ❌ |
| `tags` | Tags para los recursos | `map(string)` | ❌ |

## Outputs Principales

| Output | Descripción |
|--------|-------------|
| `application_arn` | ARN de la aplicación |
| `environment_url` | URL del ambiente |
| `environment_cname` | CNAME del ambiente |

Para la lista completa de variables y outputs, consulta `variables.tf` y `outputs.tf`.

## Ejemplos

Ver la carpeta `examples/` para configuraciones específicas:
- `basic-example.tf` - Aplicación simple
- `complete-example.tf` - Aplicación con load balancer
- `worker-example.tf` - Ambiente worker


## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Roles IAM necesarios configurados
