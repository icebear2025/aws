resource "aws_ecr_repository" "product" {
  name                 = "product"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}