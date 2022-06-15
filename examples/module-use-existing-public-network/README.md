## Create Redis (1 master VMs & 2 replica VMs) + custom network injected into Redis module
This is an example of how to use the arch-redis module to deploy Redis in non-clustered configuration (1 master VMs and 2 replica VMs) with network cloud infrastrucutre elements injected into the module.
  
### Using this example
Update terraform.tfvars with the required information.

### Deploy the Redis
Initialize Terraform:
```
$ terraform init
```
View what Terraform plans do before actually doing it:
```
$ terraform plan
```

Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid         = "<tenancy_ocid>"
user_ocid            = "<user_ocid>"
fingerprint          = "<finger_print>"
private_key_path     = "<pem_private_key_path>"

# Region
region = "<oci_region>"

# Compartment
compartment_ocid = "<compartment_ocid>"
```

Use Terraform to Provision resources:
```
$ terraform apply
```

### Destroy the Tomcat 

Use Terraform to destroy resources:
```
$ terraform destroy -auto-approve
```
