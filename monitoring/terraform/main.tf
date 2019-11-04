variable "name_prefix" {}
variable "description" {}
variable "kubernetes_worker_principal" {}

resource "aws_iam_role" "prometheus_server" {
  name               = "${var.name_prefix}-K8sPrometheusServer"
  description        = "${var.description}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${var.kubernetes_worker_principal}"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "prometheus_server_ec2_discovery" {
  name   = "${var.name_prefix}-K8sPrometheusEC2Discovery"
  role   = "${aws_iam_role.prometheus_server.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GrafanaIAMPermsForAWSIntegration",
            "Effect": "Allow",
            "Action": [
                "opsworks:Describe*",
                "opsworks:Get*",
                "opsworks:List*",
                "ec2:Describe*",
                "tag:Get*",
                "cloudwatch:List*",
                "cloudwatch:Get*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

output "prometheus_server_role_name" {
  value = "${aws_iam_role.prometheus_server.name}"
}