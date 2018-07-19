#ecs-instance-role
resource "aws_iam_role" "ecs-instance-role" {
   name                = "ecs-instance-role"
   path                = "/"
   assume_role_policy  = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

data "aws_iam_policy_document" "ecs-instance-policy" {
   statement {
       actions = ["sts:AssumeRole"]

       principals {
           type        = "Service"
           identifiers = ["ec2.amazonaws.com"]
       }
   }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role       = "${aws_iam_role.ecs-instance-role.name}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-ec2-role" {
   name = "ecs-ec2-role"
   path = "/"
   roles = ["${aws_iam_role.ecs-instance-role.id}"]
   provisioner "local-exec" {
     command = "sleep 10"
   }
}

#ecs-service-role

resource "aws_iam_role" "ecs-service-role" {
   name                = "ecs-service-role"
   path                = "/"
   assume_role_policy  = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
   role       = "${aws_iam_role.ecs-service-role.name}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
   statement {
       actions = ["sts:AssumeRole"]

       principals {
           type        = "Service"
           identifiers = ["ecs.amazonaws.com"]
       }
   }
}
