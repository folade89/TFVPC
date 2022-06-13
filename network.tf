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

#create subnet in us-west-2
resource "aws_subnet" "aws_subnet_1_worker" {
  provider          = aws.region-worker
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc-worker.id
  cidr_block        = "192.168.1.0/24"
}


# Peering request from us-east-1
resource "aws_vpc_peering_connection" "east-west" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc-worker.id
  vpc_id      = aws_vpc.vpc-master.id
  peer_region = var.region-worker

  tags = {
    Side = "Requester"
  }


}

# Peering accept to us-east-1
resource "aws_vpc_peering_connection_accepter" "west-east1" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.east-west.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

#create route table in us-east-1
resource "aws_route_table" "internetr" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc-master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mgw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.east-west.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "Master-Region-RT"
  }
}

#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc-master.id
  route_table_id = aws_route_table.internetr.id
}

#Create route table in us-west-2
resource "aws_route_table" "internetworker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc-worker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wgw.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.east-west.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

#Overwrite default route table of VPC(Worker) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc-worker.id
  route_table_id = aws_route_table.internetworker.id

}

