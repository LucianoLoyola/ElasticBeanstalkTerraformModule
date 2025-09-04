# Data source para obtener el último stack solution si no se especifica
data "aws_elastic_beanstalk_solution_stack" "latest" {
  count = var.solution_stack_name == null && var.platform_arn == null ? 1 : 0

  most_recent = true
  name_regex  = var.solution_stack_name_regex
}

# Usar el stack solution obtenido si no se especifica uno
locals {
  solution_stack_name = var.solution_stack_name != null ? var.solution_stack_name : (
    var.platform_arn != null ? null : data.aws_elastic_beanstalk_solution_stack.latest[0].name
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

  dynamic "setting" {
    for_each = var.environment_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
      resource  = lookup(setting.value, "resource", null)
    }
  }

  tags = var.tags

  depends_on = [
    aws_elastic_beanstalk_application.this,
    aws_elastic_beanstalk_application_version.this,
    aws_elastic_beanstalk_configuration_template.this
  ]
}
