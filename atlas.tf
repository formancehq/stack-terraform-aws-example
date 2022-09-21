resource "mongodbatlas_custom_dns_configuration_cluster_aws" "this" {
  project_id = var.atlas_project_id
  enabled    = true
}

resource "mongodbatlas_project_ip_access_list" "this" {
  project_id = var.atlas_project_id
  cidr_block = module.vpc.vpc_cidr_block
  comment    = "Allow AWS CIDR"
}

resource "mongodbatlas_network_container" "this" {
  project_id       = var.atlas_project_id
  atlas_cidr_block = "10.168.240.0/21"
  provider_name    = "AWS"
  region_name      = "EU_WEST_1"
}

# Create the peering connection request
resource "mongodbatlas_network_peering" "this" {
  accepter_region_name   = "eu-west-1"
  project_id             = var.atlas_project_id
  container_id           = mongodbatlas_network_container.this.id
  provider_name          = "AWS"
  route_table_cidr_block = module.vpc.vpc_cidr_block
  vpc_id                 = module.vpc.vpc_id
  aws_account_id         = data.aws_caller_identity.this.account_id
}

# the following assumes an AWS provider is configured
# Accept the peering connection request
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = mongodbatlas_network_peering.this.connection_id
  auto_accept               = true
}

resource "aws_route" "private" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.168.240.0/21"
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

resource "aws_route" "public" {
  route_table_id            = module.vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.168.240.0/21"
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

resource "mongodbatlas_advanced_cluster" "main" {
  project_id             = var.atlas_project_id
  name                   = "${local.name}-payments"
  cluster_type           = "REPLICASET"
  backup_enabled         = true
  mongo_db_major_version = "5.0"
  pit_enabled = true
  replication_specs {
    region_configs {
      electable_specs {
        instance_size = "M10"
        node_count    = 3
      }
      auto_scaling {
        disk_gb_enabled = true
        compute_enabled = true
        compute_scale_down_enabled = true
        compute_min_instance_size = "M10"
        compute_max_instance_size = "M40"
      }
      provider_name = "AWS"
      priority      = 7
      region_name   = "EU_WEST_1"
    }
  }
}

resource "random_password" "atlas" {
  length           = 16
  special          = false
}

resource "mongodbatlas_database_user" "user" {
  username           = "formance"
  password           = random_password.atlas.result
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }

  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }

  scopes {
    type = "CLUSTER"
    name = mongodbatlas_advanced_cluster.main.name
  }
}