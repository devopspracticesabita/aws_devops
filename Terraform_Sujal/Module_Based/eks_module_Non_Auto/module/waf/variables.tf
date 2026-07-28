variable "environment_name" {
  type = string
}

variable "rate_limit" {
  type    = number
}

variable "tags" {
  type    = map(string)
  default = {}
}