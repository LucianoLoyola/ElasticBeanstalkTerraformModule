# Políticas IAM para Worker Environment

Este directorio contiene las políticas IAM personalizadas para el entorno worker de Elastic Beanstalk.

## Políticas del Service Role

### `worker-service-monitoring.json`
**Rol:** Service Role  
**Propósito:** Proporciona permisos mejorados de monitoreo y gestión de colas para el servicio Worker
**Permisos incluidos:**
- SQS: consulta de atributos y URLs de las colas del worker
- CloudWatch: métricas y estadísticas de monitoreo
- CloudWatch Logs: gestión de logs específicos del worker
- SNS: notificaciones de Elastic Beanstalk
- EventBridge: eventos personalizados

## Políticas del EC2 Instance Role

### `worker-sqs-access.json`
**Rol:** EC2 Instance Role  
**Propósito:** Acceso completo a las colas SQS del worker y buckets S3 relacionados
**Permisos incluidos:**
- `sqs:*` en colas específicas del worker
- `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` en buckets de la aplicación

### `database-access.json`
**Rol:** EC2 Instance Role  
**Propósito:** Acceso a bases de datos RDS y secretos en AWS Secrets Manager
**Permisos incluidos:**
- `rds:DescribeDBInstances`, `rds:DescribeDBClusters` para información de BD
- `rds-db:connect` para conexión directa a BD
- `secretsmanager:GetSecretValue` para obtener credenciales

## Uso

Estas políticas se cargan automáticamente en `terragrunt.hcl` usando la función `file()`:

```hcl
# Service Role policies
service_role_custom_policies = [
  {
    name   = "WorkerServiceMonitoring"
    policy = file("${get_terragrunt_dir()}/policies/worker-service-monitoring.json")
  }
]

# EC2 Instance Role policies
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
```

## Ventajas de esta Estructura

1. **Separación de responsabilidades**: Lógica de infraestructura vs. políticas IAM
2. **Reutilización**: Las políticas pueden compartirse entre entornos
3. **Control de versiones**: Cada política puede versionarse independientemente
4. **Legibilidad**: El `terragrunt.hcl` se mantiene limpio y enfocado
5. **Mantenimiento**: Más fácil revisar y modificar políticas específicas

## Buenas Prácticas

- Usar principio de menor privilegio
- Especificar recursos ARN específicos cuando sea posible
- Documentar el propósito de cada permiso
- Revisar políticas regularmente para optimizar permisos
