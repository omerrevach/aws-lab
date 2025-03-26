provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "aws-lab-artifacts-omer"
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codebuild_project" "build_project" {
  name         = "aws-lab-build"
  service_role = aws_iam_role.codebuild_role.arn

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = var.dockerhub_username
    }

    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = var.dockerhub_password
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "APP_REPO"
      value = var.github_repo # "omerrevach/aws-lab"
    }

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = var.github_oauth_token
      type  = "SECRETS_MANAGER"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "aws-lab-pipeline"
  role_arn = aws_iam_role.codebuild_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "omerrevach"
        Repo       = "aws-lab"
        Branch     = "main"
        OAuthToken = var.github_oauth_token
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }
}
