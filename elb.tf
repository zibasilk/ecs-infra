############################################ LB & LISTENERS ######################################
resource "aws_lb" "alb" {
    name = "${var.env}-public"
    load_balancer_type = "application"
    subnets = var.env == "prod" ? data.aws_subnets.public_subnets.ids : data.aws_subnets.private_subnets.ids  
    security_groups = data.aws_security_group.sg_default.id 
    enable_http2 = true
    internal = var.internal 
    ip_address_type = "ipv4"
    enable_cross_zone_load_balancing = true
    idle_timeout = 180
}

resource "aws_alb_listener" "port_80" {
    load_balancer_arn = aws_lb.alb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}

#Target Group 
resource "aws_lb_target_group" "tg" {
    name = "tg-${var.env}"
    target_type = "ip"
    ip_address_type = "ipv4"
    protocol = "HTTP"
    vpc_id = data.aws_vpc.vpc.id
    health_check {
        path = "/health"
        healthy_threshold = 2
        unhealthy_threshold = 2
        interval = 60
        matcher = "200-299"
        port = 8411
    }
    stickiness {
        enabled = false
        type = "lb_cookie"
    }
}