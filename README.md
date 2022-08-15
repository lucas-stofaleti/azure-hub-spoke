# Azure Hub Spoke

The following Terraform files create a Hub-Spoke network in Azure.
More information on this architecture can be found at this [link](https://docs.microsoft.com/pt-br/azure/architecture/reference-architectures/hybrid-networking/hub-spoke?tabs=cli).
## Installation

To create the infrastructure.

```bash
  cp terraform.tfvars.template terraform.tfvars
```

Change the values as desired.

```hcl
#---------------------------
# Configure Hub Network
#---------------------------
hub = {
  cidr    = ["10.0.0.0/16"]
  subnets = ["10.0.0.0/24", ...] # As many as needed
  firewall = {
    cidr = "10.0.1.0/24"
  }
  location = "brazilsouth"
}

#---------------------------
# Configure Spoke Networks
#---------------------------
spoke = [
  {
    cidr     = ["192.168.0.0/16"]
    subnets  = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"] # As many as needed
    location = "eastus"
  },
  {
    cidr     = ["172.16.0.0/16"]
    subnets  = ["172.16.0.0/24", "172.16.1.0/24"] # As many as needed
    location = "uksouth"
  },
  {
    cidr     = ["10.1.0.0/16"]
    subnets  = ["10.1.0.0/24"] # As many as needed
    location = "brazilsouth"
  }
]

#---------------------------
# Configure Prefix Name
#---------------------------
name = "lab"

#---------------------------
# Configure Linux Access
#---------------------------
linux_config = {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNJLoMCLL58diNDQUpCPd5m+76BMG91VFGMZYsqA6q078MPuDdHEiPCAgnHbuoExXBddDV5hVSTQhWDn9+1slUEeFrGlFKYN2mwiDpxBpyipBNBnsuoz4/s4KzudXin+HXApZiwvgpFPrq8Xj4c9Kw6hKKnIT36lW3tph2gAqUHKC570ZDV2QHuBGvMwBSNPwJiBYSSrHtj9U7rMBAtsT7IFriCajw9TRciXg3lE9OKpSZCvHMhvkenn1difTtjXYljNpj5CQ5GsbFIkqpuCG10u/dUPuBntGTXYaFDcnqTxQKXjBz+afyA4msQ5PsghOezxh+o8V0A8X2Y1skEvX77CjO840aRmR0yPd3a7GpRO8VZngQKsCqZc/JiaUzV1Uh/1Gm+bJbWaAShxHHCU7tOvYpmYEjsAt0p3XBsIwJ13rVNisod6CtW9d6cQBftdct44mEZKblMAiGTWXwEEeUl0x7qaGlPOTIRs4GRC0FcWQtG/w9ynr3M1C4kW+Ngis= lucas@Lenovo"
  username = "adminuser"
}
```

Create the Infraestructure.

```bash
  terraform validate
  terraform plan
  terraform apply
```