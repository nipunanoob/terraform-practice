resource "aws_iam_user" "tf-user" {
  name = "tf-user"
}

resource "aws_iam_user_policy" "tf-readonly" {
  user = aws_iam_user.tf-user.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}

resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group_membership" "team" {
  name  = "tf-group-membership"
  group = aws_iam_group.developers.name
  users = [
    aws_iam_user.tf-user.name
  ]

}

resource "aws_iam_group_policy" "developer_policy" {
  group = aws_iam_group.developers.name
  name  = "developer_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAccessGrants",
          "s3:ListAccessGrantsInstances",
          "s3:ListAccessPointsForObjectLambda",
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
        ],
        "Resource" : [
          "*"
        ]
      },
    ]
  })

}

# resource "aws_iam_service_linked_role" "elasticbeanstalk_tf" {
    # aws_service_name = "elasticbeanstalk.amazonaws.com"
# }