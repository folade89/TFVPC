resource "aws_vpc" "vpc-master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "master-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc-worker" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "mgw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc-master.id
}

resource "aws_internet_gateway" "wgw" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc-worker.id
}

data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

#create subnet  # 1 in us-east-1
resource "aws_subnet" "aws_subnet_1" {
  provider          = aws.region-worker
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc-master.id
  cidr_block        = "10.0.1.0/24"
}

#create subnet  # 2 in us-east-1
resource "aws_subnet" "aws_subnet_2" {
  provider          = aws.region-worker
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc-master.id
  cidr_block        = "10.0.2.0/24"
}

#create subnet in us-east-2
resource "aws_subnet" "aws_subnet_1_worker" {
  provider          = aws.region-worker
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc-worker.id
  cidr_block        = "192.168.1.0/24"
}



