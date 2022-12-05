#security_group
resource "aws_security_group" "Fb-sg" {
  name        = "fb-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.stage-vpc.id

  ingress {
    description = "admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.249.77.103/32"]
  }
  ingress {
    description     = "admin"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    description = "admin"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "filebit-sg"
  }
}
data "template_file" "filebituser" {
  template = file("fb-user-data.sh")

}
#instance
resource "aws_instance" "Fb" {
  ami           = var.ami_ubuntu
  instance_type = var.type
  subnet_id     = aws_subnet.privatesubnet[2].id
  # availability_zone = data.aws_availability_zones.available.names[0]
  key_name               = aws_key_pair.demo.id
  vpc_security_group_ids = [aws_security_group.Fb-sg.id]
  user_data              = data.template_file.filebituser.rendered

  tags = {
    Name = "Fb"
  }
}



# alb target-group
resource "aws_lb_target_group" "siva-tg-filebit" {
  name     = "filebit-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.stage-vpc.id
}

resource "aws_lb_target_group_attachment" "siva-tg-attachment-filebit" {
  target_group_arn = aws_lb_target_group.siva-tg-filebit.arn
  target_id        = aws_instance.Fb.id
  port             = 8080
}



# alb-listner_rule
resource "aws_lb_listener_rule" "siva-filebit-hostbased" {
  listener_arn = aws_lb_listener.siva-alb-listener.arn
  #   priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.siva-tg-filebit.arn
  }

  condition {
    host_header {
      values = ["filebit.siva.quest"]
    }
  }
}

