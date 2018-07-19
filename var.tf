variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "us-west-1"
}
variable "PATH_TO_PRIVATE_KEY" {
  default = "mykey"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "mykey.pub"
}
variable "ECS_INSTANCE_TYPE" {
  default = "t2.large"
}
variable "ECS_AMIS" {
  type = "map"
  default = {

    us-west-1 = "ami-4aa04129"
  }
}
variable "alarms_email" {}
variable "bucket_name" {
        default = "terraformecs3"
}
