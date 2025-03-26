resource "aws_codebuild_project" "lab_app_build" {
  name          = "lab-docker-pipeline"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
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
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/YOUR_USERNAME/aws-lab"
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  source_version = "lab-pipeline"

  tags = {
    Name = "lab-docker-build"
  }
}
