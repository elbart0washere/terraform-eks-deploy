### Prerequisitos
Crear los usuarios administradores de EKS en IAM (con acceso programatico), agregarlos a la variable "eks_users" dentro de terraform.tfvars.
Recorda aplicar el configmap (output) para que tus workers hagan join de manera automatica.
Tener instalado iam-authenticator, kubectl y helm.

## Terraform EKS provision 
Module to provision a Kubernetes orchestrated application.
This will deploy:
1.  A VPC, with the input block you define.
2.  private subnets for the Kubernetes workers, and X public subnets for any need.
3.  Everything necessary for your workers node to scale.
 
## Provisioning
1.  Init and deploy first terraform files
```bash
terraform init 
terraform plan 
terraform apply 
```

2.  Write terraform outputs to files
```bash
terraform output config_map_aws_auth > config-map-aws-auth.yaml
terraform output kubeconfig > kubeconfig.yaml
```
3.  Export `KUBECONFIG` variable to the `kubeconfig.yaml`  full path. 

4.  Apply config map
```bash
aws eks update-kubeconfig --name <<clustername> --profile <<profile>>
kubectl apply -f config-map-aws-auth.yaml
```

5.  Verify that EKS Worker nodes have joined the cluster by running `kubectl get nodes --watch`

6. Install Helm & deploy autoscaler
```bash
kubectl create ns tiller
kubectl create -f resources/eks/rbac-config-helm.yml 
helm init --service-account tiller
helm fetch stable/cluster-autoscaler && tar -zxf cluster-autoscaler-0.13.2.tgz
```

7.  Config values for autoscaler chart
```yaml
edit cluster-autoscaler/values.yaml
- clusterName: <<clustername>>
- awsRegion: <<region>>
- sslCertPath: /etc/kubernetes/pki/ca.crt
- rbac:
    ## If true, create & use RBAC resources
    ##
    create: true
- scale-down-enabled
- min-replica-count
- scale-down-utilization-threshold
- scale-down-non-empty-candidates-count
- scan-interval

Change values:
sslCertPath: /etc/ssl/certs/ca-certificates.crt
sslCertPath: /etc/kubernetes/pki/ca.crt

sslCertHostPath: /etc/kubernetes/pki/ca.crt
sslCertHostPath: /etc/ssl/certs/ca-certificates.crt
```
8. `helm install --name autoscaler stable/cluster-autoscaler -f cluster-autoscaler/values.yaml`