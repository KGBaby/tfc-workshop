##-----------------------------------------##
##           Create AWS IAM Role for DD          ##
## ----------------------------------------##

#Call the AWS Caller Identity Service to get AWS Account ID
data "aws_caller_identity" "current" {}

#This is public data - AWS ARN #
data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        "${datadog_integration_aws.sandbox.external_id}"
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    actions = ["apigateway:GET",
                "autoscaling:Describe*",
                "backup:List*",
                "budgets:ViewBudget",
                "cloudfront:GetDistributionConfig",
                "cloudfront:ListDistributions",
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetTrailStatus",
                "cloudtrail:LookupEvents",
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*",
                "codedeploy:List*",
                "codedeploy:BatchGet*",
                "config:Describe*",
                "directconnect:Describe*",
                "dynamodb:List*",
                "dynamodb:Describe*",
                "ec2:Describe*",
                "ec2:Get*",
                "ecs:Describe*",
                "ecs:List*",
                "eks:List*",
                "elasticache:Describe*",
                "elasticache:List*",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeTags",
                "elasticfilesystem:DescribeAccessPoints",
                "elasticloadbalancing:Describe*",
                "elasticmapreduce:List*",
                "elasticmapreduce:Describe*",
                "es:ListTags",
                "es:ListDomainNames",
                "es:DescribeElasticsearchDomains",
                "events:CreateEventBus",
                "fsx:DescribeFileSystems",
                "fsx:ListTagsForResource",
                "health:DescribeEvents",
                "health:DescribeEventDetails",
                "health:DescribeAffectedEntities",
                "iam:List*",
                "kinesis:List*",
                "kinesis:Describe*",
                "lambda:GetPolicy",
                "lambda:List*",
                "logs:DeleteSubscriptionFilter",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:DescribeSubscriptionFilters",
                "logs:FilterLogEvents",
                "logs:PutSubscriptionFilter",
                "logs:TestMetricFilter",
                "organizations:Describe*",
                "organizations:List*",
                "rds:Describe*",
                "rds:List*",
                "redshift:Describe*",
                "redshift:DescribeClusters",
                "redshift:DescribeLoggingStatus",
                "route53:List*",
                "s3:Get*",
                "s3:GetBucketLogging",
                "s3:GetBucketLocation",
                "s3:GetBucketNotification",
                "s3:GetBucketTagging",
                "s3:ListAllMyBuckets",
                "s3:PutBucketNotification",
                "ses:Get*",
                "sns:List*",
                "sns:Publish",
                "sqs:ListQueues",
                "states:ListStateMachines",
                "states:DescribeStateMachine",
                "support:DescribeTrustedAdvisor*",
                "support:RefreshTrustedAdvisorCheck",
                "tag:GetResources",
                "tag:GetTagKeys",
                "tag:GetTagValues",
                "xray:BatchGetTraces",
                "xray:GetTraceSummaries"]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  name = "DatadogAWSIntegrationPolicyV2"
  policy = "${data.aws_iam_policy_document.datadog_aws_integration.json}"
}

resource "aws_iam_role" "datadog_aws_integration" {
  name = "DatadogAWSIntegrationRoleV2"
  description = "Role for Datadog AWS Integration"
  assume_role_policy = "${data.aws_iam_policy_document.datadog_aws_integration_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role = "${aws_iam_role.datadog_aws_integration.name}"
  policy_arn = "${aws_iam_policy.datadog_aws_integration.arn}"
}

# Attach policy for CSPM
resource "aws_iam_role_policy_attachment" "aws_security_audit" {
  role = "${aws_iam_role.datadog_aws_integration.name}"
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

##-----------------------------------------##
##            Enable the AWS integration           ##
## ----------------------------------------##

resource "datadog_integration_aws" "sandbox" {
  account_id  = "${data.aws_caller_identity.current.account_id}"
  role_name   = "DatadogAWSIntegrationRoleV2"
  cspm_resource_collection_enabled = true
  host_tags = ["aws_account:${data.aws_caller_identity.current.account_id}","event:aws-x-datadog"]
}

resource "datadog_integration_aws_tag_filter" "rds" {
depends_on = [
  datadog_integration_aws.sandbox
]
  account_id     = "${data.aws_caller_identity.current.account_id}"
  namespace      = "rds"
  tag_filter_str = "customer:storedog"
}

resource "datadog_integration_aws_tag_filter" "lambda" {
depends_on = [
  datadog_integration_aws.sandbox
]
  account_id     = "${data.aws_caller_identity.current.account_id}"
  namespace      = "lambda"
  tag_filter_str = "customer:storedog"
}
