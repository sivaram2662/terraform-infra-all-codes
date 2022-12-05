#apache-security group
resource "aws_security_group" "apache" {
  name        = "apache"
  description = "this is using for securitygroup"
  vpc_id      = aws_vpc.stage-vpc.id

  ingress {
    description = "this is inbound rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.249.77.103/32"]
  }
  ingress {
    description = "this is inbound rule"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "this is inbound rule"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "this is inbound rule"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "apache"
  }
}
#apacheuserdata
data "template_file" "apacheuser" {
  template = file("apache.sh")

}
# apache instance
resource "aws_instance" "apache" {
  ami                    = var.ami_ubuntu
  instance_type          = var.type_biger
  subnet_id              = aws_subnet.privatesubnet[2].id
  vpc_security_group_ids = [aws_security_group.apache.id]
  key_name               = aws_key_pair.demo.id
  user_data              = data.template_file.apacheuser.rendered
  tags = {
    Name = "stage-apache"
  }
}

# alb target-group
resource "aws_lb_target_group" "siva-tg-apache" {
  name     = "tg-apache"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-apache" {
  target_group_arn = aws_lb_target_group.siva-tg-apache.arn
  target_id        = aws_instance.apache.id
  port             = 80
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-apache-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-apache.arn
  }

  condition {
    host_header {
      values = ["apache.siva.quest"]
    }
  }
}

# alb target-group
resource "aws_lb_target_group" "siva-tg-sonar" {
  name     = "tg-sonar"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-sonar" {
  target_group_arn = aws_lb_target_group.siva-tg-sonar.arn
  target_id        = aws_instance.apache.id
  port             = 9000
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-sonar-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-sonar.arn
  }

  condition {
    host_header {
      values = ["sonarqube.siva.quest"]
    }
  }
}

