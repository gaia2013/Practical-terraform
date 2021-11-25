# public network と private network を作成し,その後multiAZ化する。


# list7.1: VPCの定義
resource "aws_vpc" "example" {
  cidr_block		= "10.0.0.0/16"
  enable_dns_support	= true
  enable_dns_hostnames	= true

  tags = {
    Name  = "example"
  }
}

resource "aws_subnet" "public_0" {
  vpc_id		  = aws_vpc.example.id
  cidr_block		  = "10.0.1.0/24"
  availability_zone	  = "ap-northeast-1a"
   map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

# internet gateway 定義
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# root table 定義
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# route 定義
resource "aws_route" "public" {
  route_table_id    = aws_route_table.public.id
  gateway_id	    = aws_internet_gateway.example.id
  destination_cidr_block  = "0.0.0.0/0"
}

# route table 関連付け
resource "aws_route_table_association" "public_0" {
  subnet_id   = aws_subnet.public_0.id
  route_table_id  = aws_route_table.public.id
}
# default route の利用はアンチパターン

resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


# private subnet ていぎ
resource "aws_subnet" "private_0" {
  vpc_id  = aws_vpc.example.id
  cidr_block = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

# private route table と 関連付けの定義
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "private_0" {
  subnet_id	= aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# Elastic IP の定義
resource "aws_eip" "nat_gateway_0" {
  vpc = true
  depends_on = [aws_internaet_gateway.example]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true
  depends_on = [aws_internet_gateway.example]
}

# Network Adress Translation gateway
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id = aws_subnet.public_0.id
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_1.id
  depends_on = [aws_internet_gateway.example
}

# private route 定義
resource "aws_route" "private_0" {
  route_table_id = aws_route_table.private_0.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_0.id # gate_way_id と間違わないように！
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id = aws_route_table.private_1.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_1.id #
  destination_cidr_block = "0.0.0.0/0"
}

module "example_sg" {
  source = "./security_group"
  name = "module-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_blocks = ["0.0.0.0/0"]
}

