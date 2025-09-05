# Data source para obtener el último stack solution si no se especifica
data "aws_elastic_beanstalk_solution_stack" "latest" {
  count = var.solution_stack_name == null && var.platform_arn == null ? 1 : 0

  most_recent = true
  name_regex  = var.solution_stack_name_regex
}

# Usar el stack solution obtenido si no se especifica uno
locals {
  # Seleccionar solution stack basado en prioridad
  solution_stack_name = var.solution_stack_name != null ? var.solution_stack_name : var.platform_arn != null ? null : "64bit Amazon Linux 2 v5.8.4 running Node.js 18"

  # Referencias a los roles IAM (creados o externos)
  service_role_name = var.create_iam_roles ? aws_iam_role.beanstalk_service_role[0].name : var.service_role_name
  instance_profile_name = var.create_iam_roles ? aws_iam_instance_profile.beanstalk_ec2_profile[0].name : var.ec2_instance_role_name

  # Validaciones para configuraciones conflictivas
  custom_policies_with_existing_roles = !var.create_iam_roles && (
    length(var.service_role_custom_policies) > 0 ||
    length(var.ec2_instance_role_custom_policies) > 0 ||
    length(var.service_role_custom_managed_policies) > 0 ||
    length(var.ec2_instance_role_custom_managed_policies) > 0
  )

    using_default_role_names_without_creation = !var.create_iam_roles && (
    var.service_role_name == "aws-elasticbeanstalk-service-role" ||
    var.ec2_instance_role_name == "aws-elasticbeanstalk-ec2-role"
  )
}

# ==============================================================================
# CONFIGURATION VALIDATIONS
# ==============================================================================

# Validar que no se usen políticas personalizadas con roles existentes
resource "null_resource" "validate_custom_policies_with_existing_roles" {
  count = local.custom_policies_with_existing_roles ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "ERROR: Custom IAM policies cannot be used when create_iam_roles = false."
      echo "Either set create_iam_roles = true, or manage custom policies outside this module."
      exit 1
    EOT
  }
}

# Validar que no se usen nombres por defecto con roles existentes
resource "null_resource" "validate_default_role_names_with_existing_roles" {
  count = local.using_default_role_names_without_creation ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "ERROR: When create_iam_roles = false, you must specify existing role names."
      echo "The default role names suggest you want to create new roles, but create_iam_roles = false."
      echo "Either set create_iam_roles = true, or provide specific existing role names."
      exit 1
    EOT
  }
}

# Segundo bloque locals para settings automáticos
locals {
  # Generate automatic settings based on simplified variables
  automatic_settings = concat(
    # VPC and Networking settings
    var.vpc_id != null ? [{
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = var.vpc_id
    }] : [],
    
    length(var.ec2_subnets) > 0 ? [{
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = join(",", var.ec2_subnets)
    }] : [],
    
    length(var.elb_subnets) > 0 && var.environment_type == "LoadBalanced" ? [{
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = join(",", var.elb_subnets)
    }] : [],

    # Environment Type settings
    [{
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = var.environment_type
    }],

    # Load Balancer settings (only for LoadBalanced environments)
    var.environment_type == "LoadBalanced" ? [{
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = var.load_balancer_type
    }] : [],

    # Instance settings
    [{
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = join(",", var.instance_types)
    }],

    # Auto Scaling settings (only for LoadBalanced environments)
    var.environment_type == "LoadBalanced" ? [
      {
        namespace = "aws:autoscaling:asg"
        name      = "MinSize"
        value     = tostring(var.auto_scaling_min_size)
      },
      {
        namespace = "aws:autoscaling:asg"
        name      = "MaxSize"
        value     = tostring(var.auto_scaling_max_size)
      }
    ] : [],

    # Health check settings (only for Web tier with load balancer)
    var.environment_tier == "WebServer" && var.environment_type == "LoadBalanced" ? [
      {
        namespace = "aws:elasticbeanstalk:application"
        name      = "Application Healthcheck URL"
        value     = var.health_check_path
      }
    ] : [],

    # Worker settings (only for Worker tier)
    var.environment_tier == "Worker" && var.worker_queue_url != null ? [
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "WorkerQueueURL"
        value     = var.worker_queue_url
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "HttpPath"
        value     = var.worker_http_path
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "MimeType"
        value     = var.worker_mime_type
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "HttpConnections"
        value     = tostring(var.worker_http_connections)
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "ConnectTimeout"
        value     = tostring(var.worker_connect_timeout)
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "InactivityTimeout"
        value     = tostring(var.worker_inactivity_timeout)
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "VisibilityTimeout"
        value     = tostring(var.worker_visibility_timeout)
      },
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "RetentionPeriod"
        value     = tostring(var.worker_retention_period)
      }
    ] : [],

    # Application Environment Variables
    [for key, value in var.application_environment_variables : {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = key
      value     = value
    }]
  )
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "this" {
  name        = var.application_name
  description = var.application_description

  dynamic "appversion_lifecycle" {
    for_each = var.appversion_lifecycle != null ? [var.appversion_lifecycle] : []
    content {
      service_role          = appversion_lifecycle.value.service_role
      max_count             = appversion_lifecycle.value.max_count
      max_age_in_days       = appversion_lifecycle.value.max_age_in_days
      delete_source_from_s3 = appversion_lifecycle.value.delete_source_from_s3
    }
  }

  tags = var.tags
}

# Elastic Beanstalk Application Version
resource "aws_elastic_beanstalk_application_version" "this" {
  count = var.create_application_version ? 1 : 0

  name         = var.application_version_name != null ? var.application_version_name : "${var.application_name}-${var.application_version}"
  application  = aws_elastic_beanstalk_application.this.name
  description  = var.application_version_description
  bucket       = var.source_bundle_bucket
  key          = var.source_bundle_key
  force_delete = var.force_delete_version

  tags = var.tags
}

# Elastic Beanstalk Configuration Template (opcional)
resource "aws_elastic_beanstalk_configuration_template" "this" {
  count = var.create_configuration_template ? 1 : 0

  name                = var.configuration_template_name
  application         = aws_elastic_beanstalk_application.this.name
  description         = var.configuration_template_description
  solution_stack_name = local.solution_stack_name

  dynamic "setting" {
    for_each = var.configuration_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
      resource  = lookup(setting.value, "resource", null)
    }
  }
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "this" {
  name                   = var.environment_name
  application            = aws_elastic_beanstalk_application.this.name
  description            = var.environment_description
  solution_stack_name    = var.create_configuration_template ? null : local.solution_stack_name
  template_name          = var.create_configuration_template ? aws_elastic_beanstalk_configuration_template.this[0].name : null
  tier                   = var.environment_tier
  version_label          = var.create_application_version ? aws_elastic_beanstalk_application_version.this[0].name : var.version_label
  platform_arn           = var.platform_arn
  wait_for_ready_timeout = var.wait_for_ready_timeout
  poll_interval          = var.poll_interval

  # Settings automáticos generados por las variables simplificadas
  dynamic "setting" {
    for_each = local.automatic_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }

  # Settings configurados por el usuario (se agregan además de los automáticos)
  dynamic "setting" {
    for_each = var.environment_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
      resource  = lookup(setting.value, "resource", null)
    }
  }

  # Settings automáticos para IAM (si está habilitado)
  dynamic "setting" {
    for_each = var.create_iam_roles && var.auto_configure_iam_settings ? [1] : []
    content {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = local.instance_profile_name
    }
  }

  dynamic "setting" {
    for_each = var.create_iam_roles && var.auto_configure_iam_settings ? [1] : []
    content {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "ServiceRole"
      value     = local.service_role_name
    }
  }

  tags = var.tags

  depends_on = [
    aws_elastic_beanstalk_application.this,
    aws_elastic_beanstalk_application_version.this,
    aws_elastic_beanstalk_configuration_template.this,
    aws_iam_role.beanstalk_service_role,
    aws_iam_instance_profile.beanstalk_ec2_profile
  ]
}

# ==============================================================================
# IAM ROLES para ELASTIC BEANSTALK
# ==============================================================================

# IAM Role para el servicio de Elastic Beanstalk
resource "aws_iam_role" "beanstalk_service_role" {
  count = var.create_iam_roles ? 1 : 0
  
  name = var.service_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Políticas para el rol de servicio
resource "aws_iam_role_policy_attachment" "beanstalk_service_health" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.beanstalk_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_managed_updates" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.beanstalk_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

# IAM Role para las instancias EC2
resource "aws_iam_role" "beanstalk_ec2_role" {
  count = var.create_iam_roles ? 1 : 0
  
  name = var.ec2_instance_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Políticas para el rol de instancia EC2
resource "aws_iam_role_policy_attachment" "beanstalk_ec2_web_tier" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.beanstalk_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_worker_tier" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.beanstalk_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_multicontainer" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.beanstalk_ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# Política personalizada para S3 y CloudWatch (opcional pero recomendada)
resource "aws_iam_role_policy" "beanstalk_ec2_additional" {
  count = var.create_iam_roles && var.attach_additional_policies ? 1 : 0
  name  = "${var.ec2_instance_role_name}-additional-policy"
  role  = aws_iam_role.beanstalk_ec2_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*",
          "arn:aws:s3:::elasticbeanstalk-*/*",
          "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*"
        ]
      }
    ]
  })
}

# Instance Profile para el rol de EC2
resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  count = var.create_iam_roles ? 1 : 0
  name  = var.ec2_instance_role_name
  role  = aws_iam_role.beanstalk_ec2_role[0].name

  tags = var.tags
}

# ==============================================================================
# CUSTOM IAM POLICIES
# ==============================================================================

# Custom inline policies para Service Role
resource "aws_iam_role_policy" "service_role_custom" {
  count = var.create_iam_roles ? length(var.service_role_custom_policies) : 0
  
  name   = var.service_role_custom_policies[count.index].name
  role   = aws_iam_role.beanstalk_service_role[0].id
  policy = var.service_role_custom_policies[count.index].policy
}

# Custom managed policies para Service Role
resource "aws_iam_role_policy_attachment" "service_role_custom_managed" {
  count = var.create_iam_roles ? length(var.service_role_custom_managed_policies) : 0
  
  role       = aws_iam_role.beanstalk_service_role[0].name
  policy_arn = var.service_role_custom_managed_policies[count.index]
}

# Custom inline policies para EC2 Instance Role
resource "aws_iam_role_policy" "ec2_instance_role_custom" {
  count = var.create_iam_roles ? length(var.ec2_instance_role_custom_policies) : 0
  
  name   = var.ec2_instance_role_custom_policies[count.index].name
  role   = aws_iam_role.beanstalk_ec2_role[0].id
  policy = var.ec2_instance_role_custom_policies[count.index].policy
}

# Custom managed policies para EC2 Instance Role
resource "aws_iam_role_policy_attachment" "ec2_instance_role_custom_managed" {
  count = var.create_iam_roles ? length(var.ec2_instance_role_custom_managed_policies) : 0
  
  role       = aws_iam_role.beanstalk_ec2_role[0].name
  policy_arn = var.ec2_instance_role_custom_managed_policies[count.index]
}
