variable "name_prefix" {}
variable "description" {}
variable "kubernetes_worker_principal" {}

resource "aws_iam_role" "autoscaler_k8s_role" {
  name               = "k8s-${var.name_prefix}-AutoscalerIAMRole" 
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

resource "aws_iam_role_policy" "autoscaler_k8s_policy" {
  name   = "k8s-${var.name_prefix}-AutoscalerIAMPolicy"
  role   = "${aws_iam_role.autoscaler_k8s_role.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": [
                "*"
            ]   
        }
    ]
}
EOF
}

output "k8s_autoscaler_role_name" {
  value = "${aws_iam_role.autoscaler_k8s_role.name}"
}


