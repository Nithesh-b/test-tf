provider "aws" {
  region = "us-west-2"
}

resource "aws_launch_template" "example" {
  name_prefix   = "example-launch-template"
  image_id      = "ami-00755a52896316cee"
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}

resource "aws_autoscaling_group" "example" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = ["subnet-027c96c7967b8e580"] # Updated with private subnet ID
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "example-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name               = "example-load-balancer-new"
  availability_zones = ["us-west-2a", "us-west-2b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}