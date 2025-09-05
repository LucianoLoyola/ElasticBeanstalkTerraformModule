# ==============================================================================
# EJEMPLO DE CONFIGURACIÓN DE SECURITY GROUPS PARA ELASTIC BEANSTALK
# ==============================================================================

module "elasticbeanstalk_with_custom_sg" {
  source = "../"

  # Configuración básica de la aplicación
  application_name = "my-app"
  environment_name = "my-app-prod"
  
  # Configuración de red (requerida)
  vpc_id      = "vpc-xxxxxxxxx"
  ec2_subnets = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  elb_subnets = ["subnet-aaaaaaaaa", "subnet-bbbbbbbbb"]

  # Configuración de roles IAM
  create_iam_roles           = true
  service_role_name          = "my-app-service-role"
  ec2_instance_role_name     = "my-app-ec2-role"

  # ============================================================================
  # CONFIGURACIÓN DE SECURITY GROUPS
  # ============================================================================

  # Habilitar la creación de security groups personalizados
  create_security_groups = true
  
  # Nombre y descripción del security group
  security_group_name        = "my-app-web-sg"
  security_group_description = "Security group for my web application"

  # Reglas de INGRESO (tráfico entrante)
  security_group_ingress_rules = [
    # Acceso HTTP desde internet
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    
    # Acceso HTTPS desde internet
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    
    # Acceso SSH solo desde la VPC (para administración)
    {
      description = "SSH from VPC"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    
    # Puerto de la aplicación (Node.js/Express)
    {
      description = "Application port from ALB"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    },
    
    # Ejemplo de regla con reference a otro security group
    # {
    #   description      = "Database access"
    #   from_port        = 3306
    #   to_port          = 3306
    #   protocol         = "tcp"
    #   security_groups  = ["sg-database-xxxxxxxxx"]
    # },
    
    # Ejemplo de regla self-referencing
    # {
    #   description = "Inter-instance communication"
    #   from_port   = 8080
    #   to_port     = 8080
    #   protocol    = "tcp"
    #   self        = true
    # }
  ]

  # Reglas de EGRESO (tráfico saliente)
  security_group_egress_rules = [
    # Permitir todo el tráfico saliente (común para aplicaciones web)
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    # Ejemplos de reglas más restrictivas:
    # {
    #   description = "HTTPS to internet only"
    #   from_port   = 443
    #   to_port     = 443
    #   protocol    = "tcp"
    #   cidr_blocks = ["0.0.0.0/0"]
    # },
    # {
    #   description = "Database access"
    #   from_port   = 3306
    #   to_port     = 3306
    #   protocol    = "tcp"
    #   cidr_blocks = ["10.0.1.0/24"]  # Solo subnet de base de datos
    # }
  ]

  # Security groups adicionales (si ya tienes algunos creados)
  # additional_security_group_ids = [
  #   "sg-shared-xxxxxxxxx",
  #   "sg-monitoring-yyyyyyyyy"
  # ]

  # Otras configuraciones...
  environment_type   = "LoadBalanced"
  load_balancer_type = "application"
  instance_types     = ["t3.micro"]

  tags = {
    Environment = "production"
    Project     = "my-app"
    Owner       = "platform-team"
  }
}

# ==============================================================================
# OUTPUTS RELACIONADOS CON SECURITY GROUPS
# ==============================================================================

output "security_group_id" {
  description = "ID del security group creado"
  value       = module.elasticbeanstalk_with_custom_sg.security_group_id
}

output "security_group_arn" {
  description = "ARN del security group creado"
  value       = module.elasticbeanstalk_with_custom_sg.security_group_arn
}

output "security_group_name" {
  description = "Nombre del security group creado"
  value       = module.elasticbeanstalk_with_custom_sg.security_group_name
}

# ==============================================================================
# CASOS DE USO COMUNES
# ==============================================================================

# CASO 1: Aplicación web básica (HTTP/HTTPS + SSH admin)
# security_group_ingress_rules = [
#   {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   },
#   {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   },
#   {
#     description = "SSH Admin"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["YOUR_OFFICE_IP/32"]
#   }
# ]

# CASO 2: API backend (solo acceso desde ALB/VPC)
# security_group_ingress_rules = [
#   {
#     description = "API port from ALB"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/8"]
#   }
# ]

# CASO 3: Worker tier (sin acceso HTTP directo)
# security_group_ingress_rules = [
#   {
#     description = "SSH Admin only"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]
#   }
# ]
