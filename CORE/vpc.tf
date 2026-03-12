resource "aws_vpc" "redteam_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "redteam-vpc"
  }
}

resource "aws_subnet" "lab_subnet" {
  vpc_id     = aws_vpc.redteam_vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lab-subnet"
  }
}

resource "aws_subnet" "internal_subnet" {
  vpc_id     = aws_vpc.redteam_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "internal-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.redteam_vpc.id

  tags = {
    Name = "lab-gateway"
  }
}

resource "aws_route_table" "lab_rt" {
  vpc_id = aws_vpc.redteam_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id = aws_route_table.lab_rt.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.lab_subnet.id
  route_table_id = aws_route_table.lab_rt.id
}

resource "aws_route_table" "internal_rt" {
  vpc_id = aws_vpc.redteam_vpc.id

  tags = {
    Name = "internal-rt"
  }
}

resource "aws_route_table_association" "internal_rt_assoc" {
  subnet_id      = aws_subnet.internal_subnet.id
  route_table_id = aws_route_table.internal_rt.id
}
