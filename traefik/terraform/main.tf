variable "name_prefix" {}
variable "description" {}
variable "kubernetes_worker_principal" {}
variable "public_domain_zone_id" {}

resource "aws_iam_role" "traefik_k8s_role" {
  name               = "k8s-${var.name_prefix}-TraefikIAMRole" 
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

resource "aws_iam_role_policy" "traefik_k8s_policy" {
  name   = "k8s-${var.name_prefix}-TraefikR53IAMPolicy"
  role   = "${aws_iam_role.traefik_k8s_role.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListHostedZonesByName",
                "route53:ListResourceRecordSets",
                "route53:GetChange"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/${var.public_domain_zone_id}"
            ]
        }
    ]
}
EOF
}

output "k8s_traefik_role_name" {
  value = "${aws_iam_role.traefik_k8s_role.name}"
}



