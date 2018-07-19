resource "aws_ecs_cluster" "example-cluster" {
    name = "example-cluster"
}
resource "aws_launch_configuration" "ecs-example-launchconfig" {
  name_prefix          = "ecs-launchconfig"
  image_id             = "${lookup(var.ECS_AMIS, var.AWS_REGION)}"
  instance_type        = "${var.ECS_INSTANCE_TYPE}"
  key_name             = "${aws_key_pair.mykeypair.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs-ec2-role.id}"
  security_groups      = ["${aws_security_group.ecs-securitygroup.id}"]
  user_data            = "${file("user_data.sh")}"
  lifecycle              { create_before_destroy = true }
}
resource "aws_autoscaling_group" "ecs-example-autoscaling" {
  name                 = "ecs-example-autoscaling"
  vpc_zone_identifier  = ["${aws_subnet.omero-public-1.id}", "${aws_subnet.omero-public-2.id}"]
  launch_configuration = "${aws_launch_configuration.ecs-example-launchconfig.name}"
  min_size             = 1
  max_size             = 1
  tag {
      key = "Name"
      value = "omero"
      propagate_at_launch = true
  }
}
