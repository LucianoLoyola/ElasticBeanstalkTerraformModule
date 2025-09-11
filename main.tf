#Data source to obtain the latest solution stack if none is specified
data "aws_elastic_beanstalk_solution_stack" "latest" {
  count = var.solution_stack_name == null && var.platform_arn == null ? 1 : 0

  most_recent = true
  name_regex  = var.solution_stack_name_regex
}

#Use the stack solution obtained if none is specified
locals {
  #Select solution stack based on priority
  solution_stack_name = var.solution_stack_name != null ? var.solution_stack_name : var.platform_arn != null ? null : "64bit Amazon Linux 2 v5.8.4 running Node.js 18"

  #References to IAM roles (created or external)
  service_role_name = var.create_iam_roles ? aws_iam_role.beanstalk_service_role[0].name : var.service_role_name
  instance_profile_name = var.create_iam_roles ? aws_iam_instance_profile.beanstalk_ec2_profile[0].name : var.ec2_instance_role_name

  #Validation for conflicting configurations
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

#Validate not to use custom policies with existing roles (when create_iam_roles = false)
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


#Validate not to use default names with existing roles (when create_iam_roles = false)
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

#Second locals block for automatic settings
locals {
  #Generate automatic settings based on simplified variables
  automatic_settings = concat(
    #VPC and Networking settings
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

    #Environment Type settings
    [{
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = var.environment_type
    }],

    #Load Balancer settings (only for LoadBalanced environments)
    var.environment_type == "LoadBalanced" ? [{
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = var.load_balancer_type
    }] : [],

    #Instance settings
    [{
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = join(",", var.instance_types)
    }],

    #Auto Scaling settings (only for LoadBalanced environments)
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

    #Health check settings (only for Web tier with load balancer)
    var.environment_tier == "WebServer" && var.environment_type == "LoadBalanced" ? [
      {
        namespace = "aws:elasticbeanstalk:application"
        name      = "Application Healthcheck URL"
        value     = var.health_check_path
      }
    ] : [],

    #Worker settings (only for Worker tier)
    var.environment_tier == "Worker" && local.effective_worker_queue_url != null ? [
      {
        namespace = "aws:elasticbeanstalk:sqsd"
        name      = "WorkerQueueURL"
        value     = local.effective_worker_queue_url
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

    #Security Groups settings
    var.create_security_groups || length(var.additional_security_group_ids) > 0 ? [{
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SecurityGroups"
      value     = join(",", concat(
        var.create_security_groups ? [aws_security_group.beanstalk_ec2_sg[0].id] : [],
        var.additional_security_group_ids
      ))
    }] : [],

    #Application Environment Variables
    [for key, value in var.application_environment_variables : {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = key
      value     = value
    }]
  )
}

#Elastic Beanstalk Application
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

#Elastic Beanstalk Application Version
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

#Elastic Beanstalk Configuration Template (optional)
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

#Elastic Beanstalk Environment
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

  #Automatic settings generated from simplified variables
  dynamic "setting" {
    for_each = local.automatic_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }

  # User-configured settings (added in addition to automatic ones)
  dynamic "setting" {
    for_each = var.environment_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
      resource  = lookup(setting.value, "resource", null)
    }
  }

  # IAM automatic settings (if enabled)
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
# SECURITY GROUPS - ELASTIC BEANSTALK
# ==============================================================================


#Custom Security Group for EC2 instances
resource "aws_security_group" "beanstalk_ec2_sg" {
  count = var.create_security_groups ? 1 : 0

  name        = coalesce(var.security_group_name, "${var.application_name}-sg")
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = coalesce(var.security_group_name, "${var.application_name}-sg")
  })
}

#Ingress custom rules
resource "aws_security_group_rule" "ingress" {
  count = var.create_security_groups ? length(var.security_group_ingress_rules) : 0

  type              = "ingress"
  security_group_id = aws_security_group.beanstalk_ec2_sg[0].id

  from_port                = var.security_group_ingress_rules[count.index].from_port
  to_port                  = var.security_group_ingress_rules[count.index].to_port
  protocol                 = var.security_group_ingress_rules[count.index].protocol
  cidr_blocks              = lookup(var.security_group_ingress_rules[count.index], "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(var.security_group_ingress_rules[count.index], "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(var.security_group_ingress_rules[count.index], "prefix_list_ids", null)
  source_security_group_id = try(length(var.security_group_ingress_rules[count.index].security_groups) > 0 ? var.security_group_ingress_rules[count.index].security_groups[0] : null, null)
  self                     = lookup(var.security_group_ingress_rules[count.index], "self", null)
  description              = lookup(var.security_group_ingress_rules[count.index], "description", null)
}

#Egress custom rules
resource "aws_security_group_rule" "egress" {
  count = var.create_security_groups ? length(var.security_group_egress_rules) : 0

  type              = "egress"
  security_group_id = aws_security_group.beanstalk_ec2_sg[0].id

  from_port                = var.security_group_egress_rules[count.index].from_port
  to_port                  = var.security_group_egress_rules[count.index].to_port
  protocol                 = var.security_group_egress_rules[count.index].protocol
  cidr_blocks              = lookup(var.security_group_egress_rules[count.index], "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(var.security_group_egress_rules[count.index], "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(var.security_group_egress_rules[count.index], "prefix_list_ids", null)
  source_security_group_id = try(length(var.security_group_egress_rules[count.index].security_groups) > 0 ? var.security_group_egress_rules[count.index].security_groups[0] : null, null)
  self                     = lookup(var.security_group_egress_rules[count.index], "self", null)
  description              = lookup(var.security_group_egress_rules[count.index], "description", null)
}

# ==============================================================================
# IAM ROLES - ELASTIC BEANSTALK
# ==============================================================================

#IAM Role for the Elastic Beanstalk service
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

#Policies for the service role
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

#IAM Role for the EC2 instances
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


#Policies for the EC2 instance role
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

#Custom policy for S3 and CloudWatch (optional)
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

#Instance Profile for EC2 Role
resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  count = var.create_iam_roles ? 1 : 0
  name  = var.ec2_instance_role_name
  role  = aws_iam_role.beanstalk_ec2_role[0].name

  tags = var.tags
}

# ==============================================================================
# CUSTOM IAM POLICIES
# ==============================================================================

# Custom inline policies for Service Role
resource "aws_iam_role_policy" "service_role_custom" {
  count = var.create_iam_roles ? length(var.service_role_custom_policies) : 0
  
  name   = var.service_role_custom_policies[count.index].name
  role   = aws_iam_role.beanstalk_service_role[0].id
  policy = var.service_role_custom_policies[count.index].policy
}

# Custom managed policies for Service Role
resource "aws_iam_role_policy_attachment" "service_role_custom_managed" {
  count = var.create_iam_roles ? length(var.service_role_custom_managed_policies) : 0
  
  role       = aws_iam_role.beanstalk_service_role[0].name
  policy_arn = var.service_role_custom_managed_policies[count.index]
}

# Custom inline policies for EC2 Instance Role
resource "aws_iam_role_policy" "ec2_instance_role_custom" {
  count = var.create_iam_roles ? length(var.ec2_instance_role_custom_policies) : 0
  
  name   = var.ec2_instance_role_custom_policies[count.index].name
  role   = aws_iam_role.beanstalk_ec2_role[0].id
  policy = var.ec2_instance_role_custom_policies[count.index].policy
}

# Custom managed policies for EC2 Instance Role
resource "aws_iam_role_policy_attachment" "ec2_instance_role_custom_managed" {
  count = var.create_iam_roles ? length(var.ec2_instance_role_custom_managed_policies) : 0
  
  role       = aws_iam_role.beanstalk_ec2_role[0].name
  policy_arn = var.ec2_instance_role_custom_managed_policies[count.index]
}

# ==============================================================================
# SQS RESOURCES FOR WORKER ENVIRONMENTS
# ==============================================================================

# Dead Letter Queue (optional)
resource "aws_sqs_queue" "worker_dlq" {
  count = var.create_sqs_queue && var.environment_tier == "Worker" && var.sqs_dlq_enabled ? 1 : 0

  name                      = "${coalesce(var.sqs_queue_name, "${var.application_name}-worker-queue")}-dlq"
  delay_seconds             = var.sqs_queue_delay_seconds
  max_message_size          = var.sqs_queue_max_message_size
  message_retention_seconds = var.sqs_queue_message_retention_seconds
  receive_wait_time_seconds = var.sqs_queue_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_queue_visibility_timeout_seconds

  tags = var.tags
}

# Main SQS Queue for Worker
resource "aws_sqs_queue" "worker_queue" {
  count = var.create_sqs_queue && var.environment_tier == "Worker" ? 1 : 0

  name                      = coalesce(var.sqs_queue_name, "${var.application_name}-worker-queue")
  delay_seconds             = var.sqs_queue_delay_seconds
  max_message_size          = var.sqs_queue_max_message_size
  message_retention_seconds = var.sqs_queue_message_retention_seconds
  receive_wait_time_seconds = var.sqs_queue_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_queue_visibility_timeout_seconds

  # Dead Letter Queue configuration
  redrive_policy = var.sqs_dlq_enabled ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.worker_dlq[0].arn
    maxReceiveCount     = var.sqs_dlq_max_receive_count
  }) : null

  tags = var.tags
}

#Access policy for the main SQS queue
resource "aws_sqs_queue_policy" "worker_queue_policy" {
  count = var.create_sqs_queue && var.environment_tier == "Worker" ? 1 : 0

  queue_url = aws_sqs_queue.worker_queue[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowElasticBeanstalkWorkerAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.beanstalk_ec2_role[0].arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.worker_queue[0].arn
      }
    ]
  })
}

#Access policy for the Dead Letter Queue
resource "aws_sqs_queue_policy" "worker_dlq_policy" {
  count = var.create_sqs_queue && var.environment_tier == "Worker" && var.sqs_dlq_enabled ? 1 : 0

  queue_url = aws_sqs_queue.worker_dlq[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowElasticBeanstalkWorkerDLQAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.beanstalk_ec2_role[0].arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.worker_dlq[0].arn
      }
    ]
  })
}

#Locals to determine the queue URL
locals {
  #Determine the SQS queue URL
  effective_worker_queue_url = var.environment_tier == "Worker" ? (
    var.create_sqs_queue ? aws_sqs_queue.worker_queue[0].url : var.worker_queue_url
  ) : null
  
  #Validate that SQS configuration is valid for Worker environments
  sqs_config_invalid = var.environment_tier == "Worker" && !var.create_sqs_queue && var.worker_queue_url == null
}

#Validate that a valid configuration is provided for Worker
resource "null_resource" "validate_worker_sqs_config" {
  count = local.sqs_config_invalid ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "ERROR: For Worker environments, you must either:"
      echo "  1. Set create_sqs_queue = true (to create a new queue), OR"
      echo "  2. Set create_sqs_queue = false AND provide worker_queue_url (to use existing queue)"
      exit 1
    EOT
  }
}
