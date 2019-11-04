variable "name_prefix" {}
variable "description" {}
variable "kubernetes_worker_principal" {}

resource "aws_iam_role" "externaldns_k8s_role" {
  name               = "${var.name_prefix}-K8sExternalDns"
  description        = "${var.description}"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      },
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "AWS": "${var.kubernetes_worker_principal}"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy" "externaldns_k8s_route53_discovery" {
  name   = "${var.name_prefix}-K8sExternalDnsRoute53Discovery"
  role   = "${aws_iam_role.externaldns_k8s_role.name}"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
 ]
}
EOF
}

output "externaldns_k8s_role_name" {
  value = "${aws_iam_role.externaldns_k8s_role.name}"
}
