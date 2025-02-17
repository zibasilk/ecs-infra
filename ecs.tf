resource "aws_ecs_cluster" "cluster" {
  name = "practice-${var.env}-cluster"
  tags = {
    "Environment" : var.env
  }
}

resource "aws_ecs_cluster_capacity_providers" "cp" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

############################ SIMPLE HELLO WORLD APPLICATION ###########################
data "aws_ecr_repository" "hello_world_repo" {
  name = var.hello_world_repo
}

data "external" "hello_world_image" {
  program = [
    "aws", "--region", var.region,
    "ecr", "describe-images",
    "--repository-name", data.aws_ecr_repository.hello_world_repo.name,
    "--image-ids", "imageTag=latest",
    "--query", "{\"tags\": to_string(sort_by(imageDetails,& imagePushedAt)[-1].imageTags)}",
  ]
}

module "hello_world_container_def" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git"
  container_name  = "container"
  container_image = "${data.aws_ecr_repository.hello_world_repo.repository_url}:${jsondecode(data.external.hello_world_image.result.tags)[0]}"
  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    },
    {
        containerPort = 8411
        hostPort = 8411
        protocol = "tcp"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/hello-world"
      awslogs-stream-prefix = "hello-world"
      awslogs-region        = "us-east-1"
    }
  }
  environment = [
    {
      name  = "ENVIRONMENT"
      value = var.env
    },
    {
        name = "HEALTH_CHECK_PORT"
        value = "8411"
    }
  ]
}

module "hello_world_alb_service_task" {
  source                            = "cloudposse/ecs-alb-service-task/aws"
  version                           = "0.64.0"
  name                              = "hello-world-${var.env}-service"
  alb_security_group                = data.aws_security_group.sg_default.id
  security_group_ids                = [data.aws_security_group.sg_default.id]
  health_check_grace_period_seconds = 120
  desired_count                     = 1
  exec_enabled                      = true
  ecs_cluster_arn                   = aws_ecs_cluster.cluster.arn
  network_mode                      = "awsvpc"
  vpc_id                            = data.aws_vpc.vpc.id
  subnet_ids                        = data.aws_subnet.private_subnets.id
  task_exec_role_arn                = var.task_exec_role
  task_role_arn                     = var.task_role
  task_cpu                          = 1024
  task_memory                       = 2048
  tags = {
    "Environment" : var.env
  }
  ecs_load_balancers = [
    {
      container_name   = "container"
      container_port   = 8080
      elb_name         = ""
      target_group_arn = aws_lb_target_group.tg.id
    }
  ]
  container_definition_json = jsondecode([
    module.hello_world_container_def.json_map_object
  ])
}
