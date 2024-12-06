data "http" "myip" {
  # https://stackoverflow.com/a/53782560
  url = "https://ipv4.icanhazip.com"
}

locals {
  # golden image前のuser_data
  user_data      = <<-EOF
<powershell>
# Reset RDP password
net user Administrator "${var.rdp_password}";

# Install Windows Subsystem for Linux
wsl --install

# Download Kabu Station Installer
$exeInstaller = "http://download.r10.kabu.co.jp/kabustation/setup.exe"
$exeInstallerPath = "C:\\Users\\Administrator\\Desktop\\kabustation.exe"
(New-Object System.Net.WebClient).DownloadFile($exeInstaller, $exeInstallerPath)

# Install Chrome
$exeInstaller = "https://dl.google.com/chrome/install/375.126/chrome_installer.exe"
$exeInstallerPath = "C:\\Users\\Administrator\\Downloads\\chrome_installer.exe"
(New-Object System.Net.WebClient).DownloadFile($exeInstaller, $exeInstallerPath)
Start-Process -FilePath $exeInstallerPath -ArgumentList "/silent /install" -Wait

# Enable Auto-Login
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $registryPath -Name "DefaultUserName" -Value "Administrator"
Set-ItemProperty -Path $registryPath -Name "DefaultPassword" -Value "${var.rdp_password}"
Set-ItemProperty -Path $registryPath -Name "AutoAdminLogon" -Value "1"

# Install SSH Server (https://dev.classmethod.jp/articles/how-to-setup-windows-server-sshd-with-ec2launch-v2/)
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
$administratorsKeyPath = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
$params = @{
    Headers = @{
        "X-aws-ec2-metadata-token" = Invoke-RestMethod 'http://169.254.169.254/latest/api/token' -Method Put -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = 60 }
    }
    Uri     = 'http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key/'
}
Invoke-RestMethod @params | Out-File -FilePath $administratorsKeyPath -Encoding ascii
Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled 'True' -Profile Any
</powershell>
  EOF
  instance_names = var.instance_names != "" ? split(",", var.instance_names) : []
}

variable "instance_names" { type = string }
variable "rdp_password" { type = string } # TF_VAR_rdp_password


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


data "aws_ami" "windows_2025" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2025-Japanese-Full-Base*"] # 2022だと「内部エラーです」で起動しなかった
  }
}

data "aws_ami" "myami_windows_kabu_station" {
  owners = ["self"]
  filter {
    name   = "name"
    values = ["kabu-json-windows"]
  }
}

resource "aws_instance" "this" {
  for_each = toset(local.instance_names)
  # ゼロから作るときはREADME.mdへ
  # ami       = data.aws_ami.windows_2025.id  # Golden Imageからではなく０から作り直したい時
  # user_data = base64encode(local.user_data) # Golden Imageからではなく０から作り直したい時
  # ゴールデンイメージを使うとき
  ami                         = data.aws_ami.myami_windows_kabu_station.id
  vpc_security_group_ids      = [aws_security_group.windows.id]
  instance_type               = "t3a.medium" # USD0.056/h 2vCPU 4GiB EBSのみ 最大5ギガビット
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.this.key_name
  tags = {
    Name = "kabu-json-windows"
  }
}

data "aws_ssm_parameter" "latest_amazonlinux_2023" {
  # aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64
  # https://aws.amazon.com/jp/blogs/news/amazon-linux-2023-a-cloud-optimized-linux-distribution-with-long-term-support/
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}


data "aws_ami" "myami_linux" {
  owners = ["self"]
  filter {
    name   = "name"
    values = ["kabu-json-linux"]
  }
}

resource "aws_instance" "linux" {
  for_each = toset(local.instance_names)
  # ゼロから作るときはREADME.mdへ
  # ami = data.aws_ssm_parameter.latest_amazonlinux_2023.value
  # ゴールデンイメージを使うとき
  ami                         = data.aws_ami.myami_linux.id
  vpc_security_group_ids      = [aws_security_group.linux.id]
  instance_type               = "t4g.medium" # USD0.0336/h 2vCPU 4GiB EBSのみ 最大5ギガビット
  iam_instance_profile        = aws_iam_instance_profile.linux.name
  associate_public_ip_address = true
  availability_zone           = aws_instance.this[each.key].availability_zone
  key_name                    = data.aws_key_pair.this.key_name
  tags = {
    Name = "kabu-json-linux"
  }
}


# ed25519はWindowsでは使えないのでRSA
data "aws_key_pair" "this" {
  key_name = "kabu-json-kabustation"
}

# RSA作成コマンド
# variable "public_key" {
#   type = string
#   # environment variable TF_VAR_public_key
# }
# resource "aws_key_pair" "this" {
#   key_name   = "kabu-json-kabustation"
#   public_key = var.public_key
# }
# resource "tls_private_key" "key_pair" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "local_file" "ssh_key" {
#   filename = "kabustation/${aws_key_pair.this.key_name}.pem"
#   content  = tls_private_key.key_pair.private_key_pem
# }

data "aws_vpc" "this" {
  default = true
}

resource "aws_security_group" "windows" {
  name_prefix = "kabu-json-windows"
  vpc_id      = data.aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "linux" {
  name_prefix = "kabu-json-linux"
  vpc_id      = data.aws_vpc.this.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 通常はセッションマネージャーで踏み台にするので、実IPでの開放は不要
  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  # }
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_linux_to_windows" {
  security_group_id            = aws_security_group.windows.id
  referenced_security_group_id = aws_security_group.linux.id
  ip_protocol                  = -1
}
