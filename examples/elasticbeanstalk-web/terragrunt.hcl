# environments/prod/app/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../ElasticBeanstalkModule"
}

inputs = {
  application_name = "express-demo-app"
  environment_name = "express-demo-app-dev"
  
  # Crear roles IAM automáticamente
  create_iam_roles = true
  service_role_name = "express-demo-app-service-role"
  ec2_instance_role_name = "express-demo-app-ec2-role"
  
  # Crear versión de aplicación desde S3
  create_application_version = true
  application_version = "v1.0.2"
  source_bundle_bucket = "express-demo-app"
  source_bundle_key = "expressdemoapp-clean-20250903-225344.zip"
  
  #aws elasticbeanstalk list-available-solution-stacks
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.4 running Node.js 22"
  
  environment_settings = [
    # Instancias
    {
      namespace = "aws:ec2:instances"
      name      = "InstanceTypes"
      value     = "t3.micro"
    },
    # Load Balancer
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "LoadBalanced"
    },
    {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerType"
      value     = "application"
    },
    # Auto Scaling
    {
      namespace = "aws:autoscaling:asg"
      name      = "MinSize"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = "1"
    },
    # Networking
    {
      namespace = "aws:ec2:vpc"
      name      = "VPCId"
      value     = "vpc-0f6a5bbd2546359df"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "Subnets"
      value     = "subnet-03ce92dba629183ee,subnet-0c782c7059d7ac402,subnet-00bebdf8f9e7ce1b9"
    },
    {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = "subnet-094c810dd8345c3b5,subnet-0692800804ab0688f,subnet-0497427b04eaef497"
    },
    # Environment Variables
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "NODE_ENV"
      value     = "development"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "PORT"
      value     = "8080"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "ENVIRONMENT"
      value     = "development"
    },
    {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "DEBUG"
      value     = "false"
    }
  ]
  
  tags = {
    Environment = "development"
    Project     = "express-demo-app"
  }
}