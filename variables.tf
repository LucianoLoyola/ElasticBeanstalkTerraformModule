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

# ==============================================================================
# IAM ROLES VARIABLES
# ==============================================================================

variable "create_iam_roles" {
  description = "Whether to create IAM roles for Elastic Beanstalk. If false, assumes roles already exist with the specified names."
  type        = bool
  default     = true
}

variable "service_role_name" {
  description = "Name for the Elastic Beanstalk service role"
  type        = string
  default     = "aws-elasticbeanstalk-service-role"
}

variable "ec2_instance_role_name" {
  description = "Name for the EC2 instance role"
  type        = string
  default     = "aws-elasticbeanstalk-ec2-role"
}

variable "attach_additional_policies" {
  description = "Whether to attach additional policies for S3 and CloudWatch access"
  type        = bool
  default     = true
}

variable "auto_configure_iam_settings" {
  description = "Whether to automatically add IAM configuration to environment settings"
  type        = bool
  default     = true
}

# Custom IAM Policies
variable "service_role_custom_policies" {
  description = "List of custom IAM policy documents to attach to the service role. Only applies when create_iam_roles = true."
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "ec2_instance_role_custom_policies" {
  description = "List of custom IAM policy documents to attach to the EC2 instance role. Only applies when create_iam_roles = true."
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "service_role_custom_managed_policies" {
  description = "List of custom managed policy ARNs to attach to the service role. Only applies when create_iam_roles = true."
  type        = list(string)
  default     = []
}

variable "ec2_instance_role_custom_managed_policies" {
  description = "List of custom managed policy ARNs to attach to the EC2 instance role. Only applies when create_iam_roles = true."
  type        = list(string)
  default     = []
}

# Simplified Environment Configuration variables
variable "environment_type" {
  description = "Environment type: LoadBalanced or SingleInstance"
  type        = string
  default     = "LoadBalanced"
  validation {
    condition     = contains(["LoadBalanced", "SingleInstance"], var.environment_type)
    error_message = "Environment type must be either 'LoadBalanced' or 'SingleInstance'."
  }
}

variable "load_balancer_type" {
  description = "Load balancer type: application, classic, or network"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["application", "classic", "network"], var.load_balancer_type)
    error_message = "Load balancer type must be 'application', 'classic', or 'network'."
  }
}

variable "vpc_id" {
  description = "VPC ID where the environment will be deployed"
  type        = string
  default     = null
}

variable "ec2_subnets" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
  default     = []
}

variable "elb_subnets" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
  default     = []
}

variable "instance_types" {
  description = "EC2 instance types for the environment"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "auto_scaling_min_size" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
  default     = 1
}

variable "auto_scaling_max_size" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
  default     = 1
}

# Health Check Configuration variables
variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold_count" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "unhealthy_threshold_count" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

variable "health_check_http_code" {
  description = "HTTP status code for successful health checks"
  type        = string
  default     = "200"
}

# SQS Worker Configuration variables
variable "create_sqs_queue" {
  description = "Whether to create SQS queue for worker environments (only applies when environment_tier is Worker)"
  type        = bool
  default     = false
}

variable "sqs_queue_name" {
  description = "Name for the SQS queue to create (only used when create_sqs_queue is true)"
  type        = string
  default     = null
}

variable "sqs_queue_delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
  type        = number
  default     = 0
}

variable "sqs_queue_max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 262144
}

variable "sqs_queue_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 345600 # 4 days
}

variable "sqs_queue_receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive"
  type        = number
  default     = 10
}

variable "sqs_queue_visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 300
}

variable "sqs_dlq_enabled" {
  description = "Whether to create a dead letter queue for the main SQS queue"
  type        = bool
  default     = false
}

variable "sqs_dlq_max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to DLQ"
  type        = number
  default     = 3
}

variable "worker_queue_url" {
  description = "SQS queue URL for worker environments (used when create_sqs_queue is false)"
  type        = string
  default     = null
}

variable "worker_http_path" {
  description = "HTTP path for worker requests"
  type        = string
  default     = "/worker"
}

variable "worker_mime_type" {
  description = "MIME type for worker requests"
  type        = string
  default     = "application/json"
}

variable "worker_http_connections" {
  description = "Number of HTTP connections for worker"
  type        = number
  default     = 10
}

variable "worker_connect_timeout" {
  description = "Connection timeout in seconds for worker"
  type        = number
  default     = 5
}

variable "worker_inactivity_timeout" {
  description = "Inactivity timeout in seconds for worker"
  type        = number
  default     = 299
}

variable "worker_visibility_timeout" {
  description = "Visibility timeout in seconds for worker"
  type        = number
  default     = 300
}

variable "worker_retention_period" {
  description = "Message retention period in seconds for worker"
  type        = number
  default     = 345600
}

# Application Environment Variables
variable "application_environment_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}
