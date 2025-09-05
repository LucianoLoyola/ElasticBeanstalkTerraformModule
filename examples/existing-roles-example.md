# Ejemplo: Usando Roles Existentes

Este ejemplo muestra cómo usar el módulo con roles IAM que ya existen en tu cuenta de AWS.

## Prerrequisitos

Antes de usar este modo, asegúrate de que tienes roles IAM existentes con los permisos necesarios:

### Service Role Requerido

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Políticas AWS Managed requeridas:**
- `arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth`
- `arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy`

### EC2 Instance Role Requerido

```json
{
  "Version": "2012-10-17", 
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Políticas AWS Managed requeridas:**
- `arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier` (para WebServer)
- `arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier` (para Worker)
- `arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker`

## Configuración Terragrunt

```hcl
# terragrunt.hcl
inputs = {
  application_name = "mi-app"
  environment_name = "mi-app-prod"
  
  # Usar roles existentes
  create_iam_roles = false
  service_role_name = "mi-servicio-role-existente"
  ec2_instance_role_name = "mi-ec2-instance-profile-existente"
  
  # Configuración normal del entorno
  environment_type = "LoadBalanced"
  vpc_id = "vpc-12345678"
  # ... otras configuraciones
  
  # ❌ NO usar políticas personalizadas en este modo
  # ec2_instance_role_custom_policies = []  # Debe estar vacío
}
```

## Limitaciones

1. **No se pueden usar políticas personalizadas** a través del módulo
2. **Debes gestionar los permisos manualmente** fuera del módulo
3. **Los roles deben existir antes** de ejecutar Terraform
4. **Debes asegurar que los roles tengan** todos los permisos necesarios

## ¿Cuándo usar este modo?

- ✅ Tienes políticas de seguridad estrictas sobre creación de roles
- ✅ Ya tienes roles IAM estandarizados en tu organización
- ✅ Quieres control total sobre los permisos IAM
- ❌ **No recomendado** para casos simples o desarrollo
