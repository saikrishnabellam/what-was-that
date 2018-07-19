#internet VPC
resource "aws_vpc" "omero" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "omero"
    }
}


# Subnets
resource "aws_subnet" "omero-public-1" {
    vpc_id = "${aws_vpc.omero.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-west-1a"

    tags {
        Name = "omero-public-1"
    }
}
resource "aws_subnet" "omero-public-2" {
    vpc_id = "${aws_vpc.omero.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-west-1c"

    tags {
        Name = "omero-public-2"
    }
}

resource "aws_subnet" "omero-private-1" {
    vpc_id = "${aws_vpc.omero.id}"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-west-1a"

    tags {
        Name = "omero-private-1"
    }
}
resource "aws_subnet" "omero-private-2" {
    vpc_id = "${aws_vpc.omero.id}"
    cidr_block = "10.0.5.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "us-west-1c"

    tags {
        Name = "omero-private-2"
    }
}


# Internet GW
resource "aws_internet_gateway" "omero-gw" {
    vpc_id = "${aws_vpc.omero.id}"

    tags {
        Name = "omero"
    }
}

# route tables
resource "aws_route_table" "omero-public" {
    vpc_id = "${aws_vpc.omero.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.omero-gw.id}"
    }

    tags {
        Name = "omero-public-1"
    }
}

# route associations public
resource "aws_route_table_association" "omero-public-1-a" {
    subnet_id = "${aws_subnet.omero-public-1.id}"
    route_table_id = "${aws_route_table.omero-public.id}"
}
resource "aws_route_table_association" "omero-public-2-a" {
    subnet_id = "${aws_subnet.omero-public-2.id}"
    route_table_id = "${aws_route_table.omero-public.id}"
}
