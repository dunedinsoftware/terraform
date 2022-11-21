
variable vpc_id {
  type        = string
  description = "The VPC in which the resource will be built"
}

variable "environment" {
  type        = string
  description = "Name of the environment for which a scheduler should be created"
  default     = "default"
}

variable "subnet_id" {
  type        = string
  description = "The subnet in which to create the scheduler"
}

variable "instance_type" {
  description = "The instance type for the Scheduler EC2 instance"
  type        = string
  default     = "t2.micro"
}
