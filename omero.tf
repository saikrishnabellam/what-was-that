data "aws_ecs_task_definition" "omero-master" {
  task_definition = "${aws_ecs_task_definition.omero-master.family}"
}
data "aws_ecs_task_definition" "nginx" {
  task_definition = "${aws_ecs_task_definition.nginx.family}"
}
data "aws_ecs_container_definition" "omero-master" {
  task_definition = "${data.aws_ecs_task_definition.omero-master.id}"
  container_name  = "omero-master"
}
data "aws_ecs_container_definition" "nginx" {
  task_definition = "${data.aws_ecs_task_definition.nginx.id}"
  container_name  = "nginx"
}
#data "docker_registry_image" "labshare" {
 # name = "labshare/omero-cloudserver:v2018.0201.1"
#}
#resource "docker_image" "labshare" {
 # name          = "${data.docker_registry_image.labshare.name}"
 # pull_triggers = ["${data.docker_registry_image.labshare.sha256_digest}"]
#}
#resource "aws_ecs_cluster" "example-cluster" {
 # name = "example-cluster"
#}
resource "aws_ecs_task_definition" "omero-master" {
  family = "omero-master"
  container_definitions = "${file("app.json")}"
  volume {
    name      = "OMERO_DATA"
    host_path = "/mnt/OMERO_DATA"
  }
}
resource "aws_s3_bucket" "ecs3" {
    bucket = "${var.bucket_name}"
    acl = "public-read"

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT","POST"]
        allowed_origins = ["*"]
        expose_headers = ["ETag"]
        max_age_seconds = 3000
    }

    policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
EOF
}
resource "aws_ecs_task_definition" "nginx" {
  family = "nginx"
  container_definitions = "${file("app1.json")}"
}
resource "aws_elb" "omero-master-elb" {
  name = "omero-master-elb"
  listener {
    instance_port = 4064
    instance_protocol = "TCP"
    lb_port = 4063
    lb_protocol = "TCP"
  }
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 5
    timeout = 5
    target = "TCP:4064"
    interval = 30
  }
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  subnets = ["${aws_subnet.omero-public-1.id}","${aws_subnet.omero-public-2.id}"]
  security_groups = ["${aws_security_group.omero-elb-securitygroup.id}"]
  tags {
    Name = "omero-master-elb"
  }
}
resource "aws_alb" "ecs-load-balancer" {
   name                = "ecs-load-balancer"
   security_groups     = ["${aws_security_group.ecs-securitygroup.id}"]
   subnets             = ["${aws_subnet.omero-public-1.id}", "${aws_subnet.omero-public-2.id}"]
   tags {
     Name = "ecs-load-balancer"
   }
}
resource "aws_alb_target_group" "ecs-target-group" {
   name                = "ecs-target-group"
   port                = "80"
   protocol            = "HTTP"
   vpc_id              = "${aws_vpc.omero.id}"
   health_check {
       healthy_threshold   = "2"
       unhealthy_threshold = "2"
       interval            = "60"
       matcher             = "200"
       path                = "/webclient/login/"
       #port                = "80"
       protocol            = "HTTP"
       timeout             = "5"
   }
   tags {
     Name = "ecs-target-group"
   }
}
resource "aws_alb_listener" "alb-listener" {
   load_balancer_arn = "${aws_alb.ecs-load-balancer.arn}"
   port              = "80"
   protocol          = "HTTP"
   default_action {
       target_group_arn = "${aws_alb_target_group.ecs-target-group.arn}"
       type             = "forward"
   }
}
resource "aws_ecs_service" "omero-master" {
  name          = "omero-master"
  cluster       = "${aws_ecs_cluster.example-cluster.id}"
  desired_count = 1
  task_definition = "${aws_ecs_task_definition.omero-master.family}:${max("${aws_ecs_task_definition.omero-master.revision}", "${data.aws_ecs_task_definition.omero-master.revision}")}"
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]
  load_balancer {
    elb_name = "${aws_elb.omero-master-elb.name}"
    container_name = "omero-master"
    container_port = 4064
  }
  lifecycle { ignore_changes = ["task_definition"] }
}
resource "aws_ecs_service" "nginx" {
  name          = "nginx"
  cluster       = "${aws_ecs_cluster.example-cluster.id}"
  desired_count = 1
  task_definition = "${aws_ecs_task_definition.nginx.family}:${max("${aws_ecs_task_definition.nginx.revision}", "${data.aws_ecs_task_definition.nginx.revision}")}"
  iam_role = "${aws_iam_role.ecs-service-role.name}"
  depends_on = ["aws_alb.ecs-load-balancer"]
  load_balancer {
    target_group_arn= "${aws_alb_target_group.ecs-target-group.arn}"
    container_name = "nginx"
    container_port = 80
  }
  lifecycle { ignore_changes = ["task_definition"] }
}
