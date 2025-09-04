# Application variables
variable "application_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "application_description" {
  description = "Description of the Elastic Beanstalk application"
  type        = string
  default     = null
}

variable "appversion_lifecycle" {
  description = "Application version lifecycle configuration"
  type = object({
    service_role          = string
    max_count             = optional(number)
    max_age_in_days       = optional(number)
    delete_source_from_s3 = optional(bool)
  })
  default = null
}

# Application Version variables
variable "create_application_version" {
  description = "Whether to create an application version"
  type        = bool
  default     = false
}

variable "application_version_name" {
  description = "Name of the application version. If not provided, will use application_name-application_version"
  type        = string
  default     = null
}

variable "application_version" {
  description = "Version identifier for the application version"
  type        = string
  default     = "1.0.0"
}

variable "application_version_description" {
  description = "Description of the application version"
  type        = string
  default     = null
}

variable "source_bundle_bucket" {
  description = "S3 bucket containing the application version source bundle"
  type        = string
  default     = null
}

variable "source_bundle_key" {
  description = "S3 key for the application version source bundle"
  type        = string
  default     = null
}

variable "force_delete_version" {
  description = "Force deletion of application version"
  type        = bool
  default     = false
}

# Configuration Template variables
variable "create_configuration_template" {
  description = "Whether to create a configuration template"
  type        = bool
  default     = false
}

variable "configuration_template_name" {
  description = "Name of the configuration template"
  type        = string
  default     = null
}

variable "configuration_template_description" {
  description = "Description of the configuration template"
  type        = string
  default     = null
}

variable "configuration_settings" {
  description = "Configuration settings for the configuration template"
  type = list(object({
    namespace = string
    name      = string
    value     = string
    resource  = optional(string)
  }))
  default = []
}

# Environment variables
variable "environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
}

variable "environment_description" {
  description = "Description of the Elastic Beanstalk environment"
  type        = string
  default     = null
}

variable "solution_stack_name" {
  description = "Solution stack name for the environment"
  type        = string
  default     = null
}

variable "solution_stack_name_regex" {
  description = "Regex to match solution stack name when auto-selecting latest"
  type        = string
  default     = "^64bit Amazon Linux 2 v.* running Python .*"
}

variable "platform_arn" {
  description = "Platform ARN for the environment (alternative to solution_stack_name)"
  type        = string
  default     = null
}

variable "environment_tier" {
  description = "Elastic Beanstalk environment tier (WebServer or Worker)"
  type        = string
  default     = "WebServer"

  validation {
    condition     = contains(["WebServer", "Worker"], var.environment_tier)
    error_message = "Environment tier must be either 'WebServer' or 'Worker'."
  }
}

variable "version_label" {
  description = "Version label for the environment (used when not creating application version)"
  type        = string
  default     = null
}

variable "wait_for_ready_timeout" {
  description = "Maximum duration to wait for environment to be ready"
  type        = string
  default     = "20m"
}

variable "poll_interval" {
  description = "Time between polling for environment status"
  type        = string
  default     = "10s"
}

variable "environment_settings" {
  description = "Environment-specific configuration settings"
  type = list(object({
    namespace = string
    name      = string
    value     = string
    resource  = optional(string)
  }))
  default = []
}

# Common variables
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
