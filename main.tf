module "vpc" {
  source = "./modules/vpc"
}

module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
}

module "igw" {
  source            = "./modules/igw"
  public_subnet_ids = module.subnets.public_subnets[*].id
  vpc_id            = module.vpc.vpc_id
}

module "nat_gateway" {
  source             = "./modules/nat_gateway"
  public_subnet_id   = module.subnets.public_subnets[0].id
  private_subnet_ids = module.subnets.private_subnets[*].id
  vpc_id             = module.vpc.vpc_id
}

module "security_groups" {
  source         = "./modules/security_groups"
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

module "ec2" {
  source            = "./modules/ec2"
  ami_id            = "ami-0c02fb55956c7d316" # Example Amazon Linux AMI
  instance_type     = "t2.micro"
  public_subnet_id  = module.subnets.public_subnets[0].id
  security_group_id = module.security_groups.intra_vpc_sg_id
}

module "rds" {
  source                = "./modules/rds"
  private_subnet_ids    = module.subnets.private_subnets[*].id
  vpc_security_group_id = module.security_groups.rds_sg_id
  db_name               = "mydatabase"
  username              = "postgis"
  password              = "password123"
}

module "alb" {
  source            = "./modules/alb"
  security_group_id = module.security_groups.alb_sg_id
  public_subnet_ids = module.subnets.public_subnets[*].id
  vpc_id            = module.vpc.vpc_id
  aws_instances     = module.ec2.aws_instances
}

module "ecr" {
  source = "./modules/ecr"
}
