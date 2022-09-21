#####
# Cloudwatch
#####
resource "aws_cloudwatch_log_group" main {
  name = "/aws/ecs/formance"

  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "gateway" {
  name = "/aws/ecs/formance/gateway"

  retention_in_days = 7
}