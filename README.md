Provision AWS infrastructure to connect to HCP thru a transit gateway. This repository deploy the following AWS resources:

- VPC, subnets
- Security Group
- Routing to HCP
- Transit Gateway
- Ram resource share and association
- EC2 testing instance, keypair

Once the deployment is successful, you just have to grab the following outputs and inject them into variables of the following repository. https://github.com/kalenarndt/terraform-hcp-hcp

- resource_share_arn
- transit_gw_id

You'll have to set the following terraform variables

- create_vault_cluster: true
- vault_cluster_name
- region (The region of the HCP HVN and Vault cluster)
- transit_gateway: true
- vault_tier: dev, standard_small, standard_medium, standard_large
- vault_public_endpoint: true or false
- destination_cidr: 10.0.0.0/16
- hvn_vault_id (The ID of the HCP Vault HVN): 
- output_vault_token: true or false
- generate_vault_token: true or false
- HCP_CLIENT_SECRET (HCP credentials)
- HCP_CLIENT_ID (HCP credentials)
- AWS_ACCESS_KEY_ID (AWS credentials)
- AWS_SECRET_ACCESS_KEY (AWS credentials)