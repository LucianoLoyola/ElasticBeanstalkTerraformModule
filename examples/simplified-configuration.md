# Ejemplo de Configuración Simplificada del Módulo Elastic Beanstalk

Este ejemplo muestra cómo usar las nuevas variables simplificadas del módulo.

## Entorno Web (LoadBalanced)

```hcl
inputs = {
  # Información básica
  application_name = "mi-app"
  environment_name = "mi-app-prod"
  
  # Roles IAM automáticos
  create_iam_roles = true
  service_role_name = "mi-app-service-role"
  ec2_instance_role_name = "mi-app-ec2-role"
  
  # Versión de aplicación
  create_application_version = true
  application_version = "v1.0.0"
  source_bundle_bucket = "mi-bucket-s3"
  source_bundle_key = "mi-app-v1.0.0.zip"
  
  # Plataforma
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  # Configuración simplificada
  environment_type = "LoadBalanced"        # LoadBalanced o SingleInstance
  load_balancer_type = "application"       # application, classic, network
  
  # Red
  vpc_id = "vpc-12345678"
  ec2_subnets = ["subnet-111", "subnet-222", "subnet-333"]
  elb_subnets = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  
  # Instancias
  instance_types = ["t3.small"]
  auto_scaling_min_size = 2
  auto_scaling_max_size = 10
  
  # Health Check
  health_check_path = "/api/health"
  health_check_interval = 30
  health_check_timeout = 5
  healthy_threshold_count = 2
  unhealthy_threshold_count = 3
  health_check_http_code = "200"
  
  # Variables de entorno
  application_environment_variables = {
    NODE_ENV = "production"
    DATABASE_URL = "postgresql://..."
    API_KEY = "secret-key"
  }
}
```

## Entorno Worker

```hcl
inputs = {
  # Información básica
  application_name = "mi-app-worker"
  environment_name = "mi-app-worker-prod"
  environment_tier = "Worker"
  
  # Roles IAM automáticos
  create_iam_roles = true
  service_role_name = "mi-app-worker-service-role"
  ec2_instance_role_name = "mi-app-worker-ec2-role"
  
  # Versión de aplicación
  create_application_version = true
  application_version = "v1.0.0"
  source_bundle_bucket = "mi-bucket-s3"
  source_bundle_key = "mi-worker-v1.0.0.zip"
  
  # Plataforma
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  # Red
  vpc_id = "vpc-12345678"
  ec2_subnets = ["subnet-111", "subnet-222", "subnet-333"]
  
  # Instancias
  instance_types = ["t3.medium"]
  
  # Configuración Worker
  worker_queue_url = "https://sqs.region.amazonaws.com/account/queue-name"
  worker_http_path = "/process-job"
  worker_mime_type = "application/json"
  worker_http_connections = 20
  worker_connect_timeout = 10
  worker_inactivity_timeout = 300
  worker_visibility_timeout = 600
  worker_retention_period = 1209600
  
  # Variables de entorno
  application_environment_variables = {
    NODE_ENV = "production"
    WORKER_MODE = "true"
    MAX_JOBS_PER_WORKER = "5"
  }
}
```

## Entorno SingleInstance (Desarrollo)

```hcl
inputs = {
  # Información básica
  application_name = "mi-app"
  environment_name = "mi-app-dev"
  
  # Roles IAM automáticos
  create_iam_roles = true
  
  # Versión de aplicación
  create_application_version = true
  application_version = "v1.0.0-dev"
  source_bundle_bucket = "mi-bucket-s3"
  source_bundle_key = "mi-app-dev.zip"
  
  # Configuración simplificada para desarrollo
  environment_type = "SingleInstance"
  
  # Red
  vpc_id = "vpc-12345678"
  ec2_subnets = ["subnet-111"]
  
  # Instancias
  instance_types = ["t3.micro"]
  
  # Variables de entorno
  application_environment_variables = {
    NODE_ENV = "development"
    DEBUG = "true"
  }
}
```

## Beneficios de la Configuración Simplificada

### Antes (Configuración manual):
- ❌ 20+ configuraciones manuales por entorno
- ❌ Propenso a errores de sintaxis
- ❌ Difícil de mantener
- ❌ Duplicación de código

### Ahora (Configuración simplificada):
- ✅ Variables de alto nivel intuitivas
- ✅ Configuración automática inteligente
- ✅ Menos líneas de código
- ✅ Menos propenso a errores
- ✅ Fácil mantenimiento
- ✅ Reutilizable entre entornos

## Variables Disponibles

### Configuración de Red
- `vpc_id`: ID de la VPC
- `ec2_subnets`: Subnets para instancias EC2
- `elb_subnets`: Subnets para el Load Balancer

### Configuración de Entorno
- `environment_type`: "LoadBalanced" o "SingleInstance"
- `load_balancer_type`: "application", "classic", "network"

### Configuración de Instancias
- `instance_types`: Lista de tipos de instancia
- `auto_scaling_min_size`: Tamaño mínimo del ASG
- `auto_scaling_max_size`: Tamaño máximo del ASG

### Health Check (para LoadBalanced)
- `health_check_path`: Path del health check
- `health_check_interval`: Intervalo en segundos
- `health_check_timeout`: Timeout en segundos
- `healthy_threshold_count`: Umbral de éxito
- `unhealthy_threshold_count`: Umbral de fallo

### Worker (para tier Worker)
- `worker_queue_url`: URL de la cola SQS
- `worker_http_path`: Path HTTP para workers
- `worker_mime_type`: Tipo MIME
- `worker_http_connections`: Conexiones HTTP
- Timeouts diversos

### Variables de Entorno
- `application_environment_variables`: Map de variables de entorno
