provider "aws" {
  region = var.aws_region
}

resource "aws_codestarconnections_connection" "GitHub" {
  name          = "my-github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "pipeline" {
  name     = "my-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.GitHub.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name = "pipeline-role-new"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "build_project" {
  name          = "my-build-project"
  description   = "My build project"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5"

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/python:3.7.1"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/../codebuild/buildspec.yml")
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_s3" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_s3.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_logs.arn
}

resource "aws_iam_policy" "codebuild_s3" {
  name        = "CodeBuildS3Policy-new"
  description = "A policy that allows CodeBuild to download source code from S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-new"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild" {
  name        = "CodeBuildPolicy-new"
  description = "A policy that allows starting builds in CodeBuild"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "codebuild:StartBuild",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codebuild:BatchGetBuilds",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_logs" {
  name        = "CodeBuildLogsPolicy-new"
  description = "A policy that allows CodeBuild to create log streams in CloudWatch Logs"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogStream",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "logs:PutLogEvents",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codestar_connections" {
  name        = "CodeStarConnectionsPolicy-new"
  description = "A policy that allows CodePipeline to use CodeStar Connections"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codestar_connections" {
  role       = aws_iam_role.pipeline.name
  policy_arn = aws_iam_policy.codestar_connections.arn
}

resource "aws_iam_policy" "s3" {
  name        = "S3Policy-new"
  description = "A policy that allows uploading to S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::*/*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_startbuild" {
  name        = "codebuild_startbuild_policy"
  description = "Allows CodeBuild StartBuild action"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "codebuild:StartBuild",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "pipeline_codebuild_startbuild" {
  role       = aws_iam_role.pipeline.name
  policy_arn = aws_iam_policy.codebuild_startbuild.arn
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.pipeline.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "random_pet" "bucket_suffix" {
  length = 2
  prefix = "techstarter"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = random_pet.bucket_suffix.id
}