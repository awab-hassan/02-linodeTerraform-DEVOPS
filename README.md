# LKE Cluster Deployment with Terraform

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![Linode](https://img.shields.io/badge/Linode-00A36C?style=flat-square&logo=linode&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-D22128?style=flat-square&logo=apache&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-13AA52?style=flat-square&logo=mongodb&logoColor=white)

## Overview

Deployed a full Kubernetes stack on Linode Kubernetes Engine (LKE) entirely through Terraform. The project covers cluster provisioning, application deployment (Apache + MongoDB), credential management, and Horizontal Pod Autoscaling — all defined as infrastructure code using the Linode Terraform provider.

## Architecture

![Architecture Diagram](./architecture.png)

The deployment flow:
- **Terraform** provisions the LKE cluster on Linode via the Linode provider
- **Apache** deployed as a Kubernetes Deployment + Service via Terraform
- **MongoDB** deployed with credentials configured and a ClusterIP Service
- **HPA** configured to autoscale pods based on CPU utilization

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Cloud platform | Linode (Akamai Cloud) |
| Kubernetes engine | LKE (Linode Kubernetes Engine) |
| Infrastructure as Code | Terraform + Linode provider |
| Web server | Apache |
| Database | MongoDB |
| Autoscaling | Kubernetes HPA |

## What Was Built

**1. Linode Terraform provider setup**
- Researched and configured the Linode provider for Terraform
- Set up authentication and provider version pinning

**2. LKE cluster provisioned with Terraform**
- Defined node pools, Kubernetes version, and region in Terraform
- Full cluster lifecycle managed as code

**3. Apache deployment via Terraform**
- Kubernetes `Deployment` and `Service` resources written in Terraform
- Exposed via LoadBalancer service

**4. MongoDB deployment with credentials**
- MongoDB `Deployment` and `Service` deployed via Terraform
- Database credentials configured securely within the manifest

**5. Horizontal Pod Autoscaler**
- HPA configured via Terraform to scale pods on CPU utilization
- Tested scaling behaviour under load

## Project Structure

```
02-linodeTerraform-DEVOPS/
├── main.tf          (provider config, LKE cluster)
├── apache.tf        (Deployment + Service)
├── mongodb.tf       (Deployment + Service + credentials)
├── hpa.tf           (HorizontalPodAutoscaler)
├── variables.tf
└── README.md
```

## Key Learnings

- Working with the Linode Terraform provider — different from AWS but same IaC principles
- Managing Kubernetes resources directly through Terraform instead of kubectl
- Credential management for stateful workloads like MongoDB in Kubernetes