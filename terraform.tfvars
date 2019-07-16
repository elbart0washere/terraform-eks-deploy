######  GENERAL ######
aws_region = "us-east-1" //AWS region
profile = "YOURPROFILEHERE" // your aws profile (read aws configure)
aws_azs = ["a","b"] //list of AZ
env = "prd" //enviroment tag
owner = "elbart0" // owner tag
celula = "elbart0" // cell tag
key = "ssh-key-" //your ssh key previously created
vpc_cidr = "172.14.0.0/16" // cidr for vpc creation 

###### WORKER NODES AUTOSCALING GROUP ######
worker_nodes_ec2_instance_type = "t3.medium"
worker_nodes_desired_capacity = 1
worker_nodes_min_size = 1
worker_nodes_max_size = 3
access_to_ec2_file = "./resources/policies/access_to_ec2.json"
access_to_asg_file = "./resources/policies/access_to_asg.json"
worker_nodes_ami_id = "ami-0f2e8e5663e16b436"  //for eks 1.13 version ami-0f2e8e5663e16b436 us-east-1 - List AMI  source: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html

###### EKS CLUSTER ######
eks_name = "your-cluster-name_eks"  //eks cluster name
eks_version = "1.13" //eks version 
eks_public_subnets = ["172.14.1.0/24","172.14.2.0/24"] //public subnetting
eks_private_subnets = ["172.14.3.0/24","172.14.4.0/24"] //private subnetting (terraform will create a nat-gateway for each az)
access_to_eks_file = "./resources/policies/access_to_eks.json" 

###### IAM #######
eks_users = ["elbart0_terraform"]  //list of eks user, requires that you previously believe them with IAM
