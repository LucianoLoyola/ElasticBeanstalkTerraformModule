# Módulo Terraform para AWS Elastic Beanstalk

Módulo de Terraform para desplegar aplicaciones en AWS Elastic Beanstalk.

## Características

- ✅ Aplicaciones Elastic Beanstalk
- ✅ Versiones de aplicaciones con S3
- ✅ Templates de configuración reutilizables
- ✅ Ambientes Web Server y Worker
- ✅ **Gestión automática de colas SQS para Workers**
- ✅ **Soporte para Dead Letter Queues (DLQ)**
- ✅ **Security Groups personalizados con reglas configurables**
- ✅ Soporte completo para configuraciones personalizadas
- ✅ **IAM Roles con políticas personalizadas**

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
- `Elasticbeanstalk-web` - Ejemplo para web server
- `Elasticbeanstalk-worker` - Ejemplo para worker

## Gestión de Roles IAM

El módulo soporta dos modos de operación para los roles IAM:

### Modo 1: Crear Roles Automáticamente
Las policies deben estar almacenadas en el mismo directorio donde está el archivo de `terragrunt.hcl`, en una carpeta llamada "`/policies`"

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

**Ventajas:**
- El módulo crea y gestiona todos los roles
- Soporte completo para políticas personalizadas
- Permisos básicos incluidos automáticamente
- Fácil de mantener

### Modo 2: Usar Roles Existentes

```hcl
inputs = {
  # Usar roles IAM existentes
  create_iam_roles = false
  service_role_name = "mi-role-existente-service"      # DEBE EXISTIR
  ec2_instance_role_name = "mi-role-existente-ec2"     # DEBE EXISTIR
  
  # NO se pueden usar políticas personalizadas en este modo
  # ec2_instance_role_custom_policies = []  # Debe estar vacío
}
```

**Requisitos:**
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

## Security Groups Personalizados

El módulo permite crear security groups personalizados inbound y outbound rules configurables:

```hcl
inputs = {
  # Habilitar creación de security groups personalizados
  create_security_groups = true
  security_group_name = "my-app-web-sg"
  security_group_description = "Security group for my web application"

  # Reglas de ingreso (tráfico entrante)
  security_group_ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH from VPC only"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      description = "App port from ALB"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  # Reglas de egreso (tráfico saliente)
  security_group_egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # Security groups adicionales (opcionales)
  additional_security_group_ids = ["sg-existing-xxxxxxxxx"]
}
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 5.0
