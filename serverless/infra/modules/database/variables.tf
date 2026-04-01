variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable DynamoDB point-in-time recovery (PITR)"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the DynamoDB table"
  type        = bool
  default     = false # If this was production it would be set to true, but for development we want to be able to easily delete the table when needed
}

variable "enable_ttl" {
  description = "Enable TTL on items (uses 'TTL' attribute)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
