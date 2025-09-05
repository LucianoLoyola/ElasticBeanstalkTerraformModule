# Módulo Terraform para AWS Elastic Beanstalk

Módulo de Terraform para desplegar aplicaciones en AWS Elastic Beanstalk. Compatible con Terragrunt.

## Características

- ✅ Aplicaciones Elastic Beanstalk
- ✅ Versiones de aplicaciones con S3
- ✅ Templates de configuración reutilizables
- ✅ Ambientes Web Server y Worker
- ✅ **Gestión automática de colas SQS para Workers**
- ✅ **Soporte para Dead Letter Queues (DLQ)**
- ✅ Auto-detección de solution stacks
- ✅ Soporte completo para configuraciones personalizadas
- ✅ **IAM Roles con políticas personalizadas**
- ✅ **Configuración simplificada de variables**

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
| `create_iam_roles` | Crear roles IAM automáticamente | `bool` | ❌ |
| `service_role_custom_policies` | Políticas inline personalizadas para Service Role | `list(object)` | ❌ |
| `ec2_instance_role_custom_policies` | Políticas inline personalizadas para EC2 Role | `list(object)` | ❌ |
| `service_role_custom_managed_policies` | Políticas managed personalizadas para Service Role | `list(string)` | ❌ |
| `ec2_instance_role_custom_managed_policies` | Políticas managed personalizadas para EC2 Role | `list(string)` | ❌ |
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

## Gestión de Roles IAM

El módulo soporta dos modos de operación para los roles IAM:

### 🔧 Modo 1: Crear Roles Automáticamente (Recomendado)

```hcl
inputs = {
  # Crear roles IAM automáticamente
  create_iam_roles = true
  service_role_name = "mi-app-service-role"
  ec2_instance_role_name = "mi-app-ec2-role"
  
  # Políticas personalizadas (solo funciona con create_iam_roles = true)
  ec2_instance_role_custom_policies = [
    {
      name   = "CustomPolicy"
      policy = file("${get_terragrunt_dir()}/policies/custom.json")
    }
  ]
}
```

**✅ Ventajas:**
- El módulo crea y gestiona todos los roles
- Soporte completo para políticas personalizadas
- Permisos básicos incluidos automáticamente
- Fácil de mantener

### 🏗️ Modo 2: Usar Roles Existentes

```hcl
inputs = {
  # Usar roles IAM existentes
  create_iam_roles = false
  service_role_name = "mi-role-existente-service"      # DEBE EXISTIR
  ec2_instance_role_name = "mi-role-existente-ec2"     # DEBE EXISTIR
  
  # ❌ NO se pueden usar políticas personalizadas en este modo
  # ec2_instance_role_custom_policies = []  # Debe estar vacío
}
```

**⚠️ Requisitos:**
- Los roles DEBEN existir previamente en AWS
- Los roles DEBEN tener los permisos básicos de Elastic Beanstalk
- Las políticas personalizadas se deben gestionar externamente

### Políticas IAM Personalizadas

El módulo permite añadir políticas personalizadas tanto inline como managed a los roles de servicio y EC2. **Recomendamos usar archivos externos** para mantener el `terragrunt.hcl` limpio y organizado.

#### Usando Archivos Externos (Recomendado)

```hcl
# Estructura de archivos recomendada:
# my-environment/
# ├── terragrunt.hcl
# └── policies/
#     ├── README.md
#     ├── worker-sqs-access.json
#     └── database-access.json

inputs = {
  # ... otras configuraciones ...
  
  # Políticas inline personalizadas cargadas desde archivos
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
  
  # Políticas managed adicionales
  ec2_instance_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
```

#### Usando Políticas Inline (Alternativa)

```hcl
inputs = {
  # ... otras configuraciones ...
  
  # Políticas inline personalizadas para el Service Role
  service_role_custom_policies = [
    {
      name = "CustomS3Access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::mi-bucket-personalizado/*"
          }
        ]
      })
    }
  ]
  
  # Políticas managed personalizadas para el EC2 Instance Role
  ec2_instance_role_custom_managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::123456789012:policy/MiPoliticaPersonalizada"
  ]
  
  # Políticas inline personalizadas para el EC2 Instance Role
  ec2_instance_role_custom_policies = [
    {
      name = "DatabaseAccess"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "rds:DescribeDBInstances",
              "rds:Connect"
            ]
            Resource = "*"
          }
        ]
      })
    }
  ]
}


## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
- Roles IAM necesarios configurados
