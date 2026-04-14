# Copy this file to terraform.tfvars and fill in your values
# Never commit terraform.tfvars to Git — it's already in .gitignore, for now I have removed it so everyone can use it and modify accordingly.

token               = "YOUR_LINODE_API_TOKEN"
kubeconfig_path     = "/path/to/your/kubeconfig.yaml"
k8s_version         = "1.25"
label               = "default-lke"
region              = "us-west"
tags                = ["dev"]
mongo_root_username = "YOUR_MONGO_USERNAME"
mongo_root_password = "YOUR_MONGO_PASSWORD"

pools = [
  {
    type  = "g6-standard-2"
    count = 3
  }
]
