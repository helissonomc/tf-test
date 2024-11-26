resource "aws_ecr_repository" "app_ecr" {
  name                 = "app-ecr"
  image_tag_mutability = "MUTABLE"
  force_delete = true
}