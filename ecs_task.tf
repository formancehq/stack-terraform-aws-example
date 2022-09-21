data "aws_region" "current" {}

resource "aws_ecs_task_definition" "gateway" {
  family = "gateway"
  container_definitions = templatefile("task-definitions/gateway.json", {
    region           = data.aws_region.current.name
    ecs_cluster_name = module.ecs.cluster_name
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "ledger" {
  depends_on = [module.rds]
  family     = "ledger"
  container_definitions = templatefile("task-definitions/ledger.json", {
    postgresql_conn_string = local.ledger_postgresql_conn_string
    alb_endpoint           = aws_lb.main.dns_name
    msk_brokers = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[0]
    msk_username = "formance"
    msk_password = random_password.master_password.result
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
}

resource "aws_ecs_task_definition" "control" {
  family = "control"
  container_definitions = templatefile("task-definitions/control.json", {
    api_endpoint = "http://${aws_lb.main.dns_name}/api"
    alb_endpoint = aws_lb.main.dns_name
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
}

resource "aws_ecs_task_definition" "search" {
  family = "search"
  container_definitions = templatefile("task-definitions/search.json", {
    alb_endpoint   = aws_lb.main.dns_name
    opensearch_url = aws_elasticsearch_domain.opensearch.endpoint
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "search-ingester" {
  family = "search-ingester"
  container_definitions = templatefile("task-definitions/search-ingester.json", {
    alb_endpoint   = aws_lb.main.dns_name
    opensearch_url = "https://${aws_elasticsearch_domain.opensearch.endpoint}:443"
    msk_brokers = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[0]
    msk_username = "formance"
    msk_password = random_password.master_password.result
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "payments" {
  family = "payments"
  container_definitions = templatefile("task-definitions/payments.json", {
    alb_endpoint   = aws_lb.main.dns_name
    mongodb_uri = local.mongodb_uri
    msk_brokers = split(",", aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram)[0]
    msk_username = "formance"
    msk_password = random_password.master_password.result
  })
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
}
