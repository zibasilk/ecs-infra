terraform {
    source = "./Terraform"

    extra_arguments "custom_vars" {
        commands = [
            "apply",
            "plan",
            "import",
            "push",
            "refresh",
            "validate",
            "init"
        ]
        arguments = []
    }
}

inputs = {
    region = "us-east-1"
    account_id = ""
    env = "dev"
    vpc = ""
    task_role = ""
    task_exec_role = ""
    hello_world_repo = ""
    internal = "true"
    sg_default = ""
}

generate "backend" {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
terraform {
    backend "s3" {
        bucket = ""
        key = ""
        region = "us-east-1"
    }
}
EOF 
} 
