variable "environment_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "table_name" {
  type        = string
  description = "The name of the DynamoDB table"
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST" # Best for unpredictable workloads
}

variable "hash_key" {
  type        = string
  description = "The Partition Key name"
}

variable "hash_key_type" {
  type    = string
  default = "S" # S=String, N=Number, B=Binary
}

variable "range_key" {
  type        = string
  default     = ""
  description = "The Sort Key name (optional)"
}

variable "range_key_type" {
  type    = string
  default = "S"
}

variable "read_capacity" {
  type    = number
  default = 5
}

variable "write_capacity" {
  type    = number
  default = 5
}

variable "enable_pitr" {
  type    = bool
  default = true
}

variable "kms_key_arn" {
  type    = string
  default = null # Uses AWS Managed Key if null
}

variable "deletion_protection" {
  description = "Enables deletion protection for the DynamoDB table"
  type        = bool
  default     = true # Safety first!
}