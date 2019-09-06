data "template_file" "user_data_windows_client" {
  template = file("${path.module}/scripts/client.ps1")

  vars = {
    region            = var.region
    cluster_tag_value = var.cluster_tag_value
    server_ip         = aws_instance.primary[0].private_ip
  }
}

resource "aws_instance" "windows_client" {
  ami                    = "ami-06a4e829b8bbad61e"
  instance_type          = var.client_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.primary.id]
  subnet_id              = var.subnet_id
  count                  = 1
  get_password_data      = true

  #depends_on             = ["aws_instance.primary"]

  #Instance tags
  tags = {
    Name           = "${var.name_tag_prefix}-client-${count.index}"
    ConsulAutoJoin = var.cluster_tag_value
    owner          = var.owner
    TTL            = var.ttl
    created-by     = "Terraform"
  }

  user_data            = data.template_file.user_data_windows_client.rendered
  iam_instance_profile = aws_iam_instance_profile.windows_instance_profile.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "windows_instance_profile" {
  name_prefix = "${var.name_tag_prefix}-profile"
  role        = aws_iam_role.instance_role.name
}

resource "local_file" "private_key" {
  content = var.private_key_data
  filename = "${path.module}/private_key.pem"
}

data "external" "decode_password" {
  program = ["${path.root}/decrypt_password.sh", aws_instance.windows_client[0].password_data, local_file.private_key.filename]
}
