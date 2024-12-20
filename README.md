# Food In Sight

## Setup:

- Create an EC2 instance using the AMI (Team 5 Food Insight AMI)

- SSH into the “ec2-user” account on the EC2 instance

- Run `aws configure` to login to your aws account from this instance using a security key pair if you do not already have a key pair follow [these instructions](#aws-configure) to create new ones.

- Run `git clone git@github.com:SWEN-514-FALL-2024/term-project-2241-swen-514-05-team5.git`

- Run `cd term-project-2241-swen-514-05-team5/`

- Run `git checkout <branch/commit>` (This should be changed to a working commit tag on main that we want to grade instead of latest)

- If you are a developer at this point you can switch to your branch to test that branch instead

- Run `cd deployment`

- Use Vim/vi/nano or your text editor of choice to change the security key and github token to match your account's
  security key and your github access token in `terraform.tfvars`

- Run `terraform init`

- Run `terraform plan`

- Run `terraform apply`

- Enter "yes" to allow terraform to launch the new instance

- To shutdown the instance started by terraform run `terraform destroy`


## Aws Configure:

To get the necessary key and secret after running aws configure in the ec2 instance

1. Run `aws configure` in ec2 instance, if you do not have the credentials do the following

2. Go to IAM console

3. Click "Create User"

![alt text](readme-image/image.png)

4. Provide a name, Hit "Next"

![alt text](readme-image/image2.png)

5. Attach policies directly and choose "AdministratorAccess", then hit "Next"

![alt text](readme-image/image3.png)

6. "Create User"

![alt text](readme-image/image4.png)

7. Select Newly Created User

![alt text](readme-image/image5.png)

8. Go to Security Credentials. Hit "Create access key"

![alt text](readme-image/image6.png)

9. Select "Command Line Interface (CLI)", Confirm confirmation, hit "Next"

![alt text](readme-image/image7.png)

10. Enter a description and hit "Create Access Key"

![alt text](readme-image/image8.png)

11. Save the access key and secret access key in very very safe place or download csv. The key and secret key is what you will use as answers to the prompt after running aws configure in the ec2 instance.

![alt text](readme-image/image9.png)
