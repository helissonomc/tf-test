resource "aws_subnet" "public" {
  count                    = 2
  vpc_id                   = var.vpc_id
  cidr_block               = element(["10.0.1.0/24", "10.0.3.0/24"], count.index)
  availability_zone        = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch  = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                    = 2
  vpc_id                   = var.vpc_id
  cidr_block               = element(["10.0.2.0/24", "10.0.4.0/24"], count.index)
  availability_zone        = element(["us-east-1a", "us-east-1b"], count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}
