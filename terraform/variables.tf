variable "aws_region"{

    description = "AWS region to deploy resources"
    type        = string
    default     = "us-east-1"

}

variable "cluster_name" {
    description = "Name of EKS cluster"
    type        = string
    default     = "retail-store"
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "environment" {
    description = "Environemt name (dev, staging, prod)"
    type        = string
    default     = "dev"
}

variable "enable_single_nat_gateway" {
    description = "Use single NAT gateway to reduce costs (not recommended for production)"
    type        = bool
    default     = true
}

variable "kubernetes_version" {
    description = "Kubernetes version for EKS cluster"
    type        = string
    default     = "1.33"
}

variable "argocd_namespace" {
  description = "Namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}