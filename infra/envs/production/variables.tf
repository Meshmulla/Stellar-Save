# infra/envs/production/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for stellar-save.app (us-east-1)"
  type        = string
}

# CodeDeploy Configuration
variable "alb_name" {
  description = "Name of the Application Load Balancer (optional - uses default if not provided)"
  type        = string
  default     = ""
}

variable "listener_arn" {
  description = "ARN of the ALB production listener for CodeDeploy traffic shifting"
  type        = string
}

variable "blue_target_group_name" {
  description = "Name of the blue (current) target group (optional - uses default if not provided)"
  type        = string
  default     = ""
}

variable "green_target_group_name" {
  description = "Name of the green (replacement) target group (optional - uses default if not provided)"
  type        = string
  default     = ""
}

variable "canary_traffic_percentage" {
  description = "Percentage of traffic to shift to green during canary phase"
  type        = number
  default     = 10
}

variable "canary_duration_minutes" {
  description = "Duration of canary phase in minutes"
  type        = number
  default     = 5
}

variable "blue_termination_wait_minutes" {
  description = "Minutes to wait before terminating blue instances"
  type        = number
  default     = 5
}

variable "error_rate_threshold" {
  description = "Number of 5xx errors per minute to trigger automatic rollback"
  type        = number
  default     = 10
}

# ── RDS module wiring (referenced by main.tf) ─────────────────────────────────
variable "vpc_id" {
  description = "VPC ID for the primary-region RDS instance"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the primary-region RDS subnet group"
  type        = list(string)
  default     = []
}

variable "backend_security_group_ids" {
  description = "Security group IDs allowed to reach the primary-region RDS instance"
  type        = list(string)
  default     = []
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_password" {
  description = "Master DB password"
  type        = string
  default     = ""
  sensitive   = true
}

# ── Multi-region failover & geo-routing (additive, default single-region) ─────
variable "enable_multi_region" {
  description = "Enable Route53 multi-region geo/latency routing with health-check failover. Defaults false (single region)."
  type        = bool
  default     = false
}

variable "secondary_aws_region" {
  description = "Secondary AWS region for failover/replica resources. Defaults to the primary region so single-region plans are valid."
  type        = string
  default     = "us-east-1"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for the application domain (required when enable_multi_region = true)."
  type        = string
  default     = ""
}

variable "routing_record_name" {
  description = "FQDN that latency/geo routing resolves to (e.g. api.stellar-save.app)."
  type        = string
  default     = "api.stellar-save.app"
}

variable "routing_policy" {
  description = "Multi-region routing policy: 'latency' or 'geolocation'."
  type        = string
  default     = "latency"
}

variable "primary_endpoint_domain" {
  description = "ALB/CloudFront endpoint domain in the primary region."
  type        = string
  default     = ""
}

variable "secondary_endpoint_domain" {
  description = "ALB/CloudFront endpoint domain in the secondary region."
  type        = string
  default     = ""
}

# ── Cross-region RDS read replica (additive, default disabled) ────────────────
variable "enable_cross_region_replica" {
  description = "Create a read-only RDS replica in the secondary region. Defaults false."
  type        = bool
  default     = false
}

variable "replica_vpc_id" {
  description = "VPC ID in the secondary region for the read replica."
  type        = string
  default     = ""
}

variable "replica_subnet_ids" {
  description = "Private subnet IDs in the secondary region for the read replica subnet group."
  type        = list(string)
  default     = []
}

variable "replica_security_group_ids" {
  description = "Security group IDs in the secondary region allowed to reach the read replica."
  type        = list(string)
  default     = []
}

variable "replica_kms_key_id" {
  description = "KMS key (in the secondary region) used to encrypt the read replica's storage. Empty uses the region default RDS key."
  type        = string
  default     = ""
}
