There is another copy of this README file located on the AMI.
# Food In Sight
## Setup:
- Create an EC2 instance using the AMI
- SSH into the “ec2-user” account on the EC2 instance
- Run `aws configure` to login to your aws account from this instance using a security key pair
- Run cd Terraform_Team
- Use Vim/vi/nano or your text editor of choice to change the security key to match your account's
security key in "main.tf"
- Run `terraform plan`
- Run `terraform apply`
- Enter "yes" to allow terraform to launch the new instance
- To shutdown the instance started by terraform run `terraform destroy`
