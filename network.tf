# Network Configuration

#VPC
data "aws_vpc" "vpc" {
    id = var.vpc
}

#Private Subnets 
data "aws_subnets" "private_subnets" {
    filter {
        name = "tag:SubnetType"
        values = ["Private"] # insert values here
    }
}

#Public Subnets 
data "aws_subnets" "public_subnets" {
    filter {
        name = "tag:SubnetType"
        values = ["*Public*"] # insert values here
    }
}

#Security Groups 
data "aws_security_group" "sg_default" { id = var.sg_default }