resource "aws_iam_role" "this" {
  name = "kabu-json-windows-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow"
        "Principal" : {
          "Service" : ["ec2.amazonaws.com"]
        },
      },
    ]
  })
}

resource "aws_iam_role_policy_attachments_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ]
}


resource "aws_iam_instance_profile" "this" {
  name = "kabu-json-windows-role-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_instance_profile" "linux" {
  name = "kabu-json-linux-role-profile"
  role = aws_iam_role.this.name
}


data "aws_vpc" "this" {
  default = true
}

resource "aws_security_group" "windows" {
  name   = "kabu-json-windows"
  vpc_id = data.aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "linux" {
  name   = "kabu-json-linux"
  vpc_id = data.aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_linux_to_windows" {
  security_group_id            = aws_security_group.windows.id
  referenced_security_group_id = aws_security_group.linux.id
  ip_protocol                  = -1
}
