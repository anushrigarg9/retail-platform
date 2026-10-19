# DevSecOps Pipeline for a Five-Microservice Retail Platform

A complete end-to-end DevSecOps project that automates application
validation, security scanning, container publishing, infrastructure
provisioning, and GitOps-based Kubernetes deployment on AWS.

> **Project outcome:** Code changes are validated by GitHub Actions,
> container images are scanned and published to Amazon ECR, AWS
> infrastructure is managed with Terraform, and Argo CD reconciles
> Kubernetes deployments from Git-managed Helm configuration.

## Contents

-   [Overview](#overview)
-   [Key Features](#key-features)
-   [Architecture](#architecture)
-   [End-to-End Workflow](#end-to-end-workflow)
-   [Technology Stack](#technology-stack)
-   [Microservices](#microservices)
-   [CI/CD Pipeline](#cicd-pipeline)
-   [Infrastructure as Code](#infrastructure-as-code)
-   [GitOps Deployment](#gitops-deployment)
-   [Security Strategy](#security-strategy)
-   [Monitoring and Observability](#monitoring-and-observability)
-   [Repository Structure](#repository-structure)
-   [Prerequisites](#prerequisites)
-   [Run Locally](#run-locally)
-   [Deployment Overview](#deployment-overview)
-   [Validation and Troubleshooting](#validation-and-troubleshooting)
-   [Lessons Learned](#lessons-learned)
-   [Future Improvements](#future-improvements)
-   [Acknowledgements](#acknowledgements)

## Overview

This project demonstrates a DevSecOps delivery workflow for a retail
application composed of five microservices: **UI, Catalog, Cart,
Checkout, and Orders**.

The platform combines containerization, automated CI checks,
infrastructure as code, image vulnerability scanning, AWS container
registry publishing, Kubernetes deployment with Helm, and GitOps
reconciliation through Argo CD.

The objective is to make application delivery repeatable and auditable:
changes are tested and scanned before images are published, and
deployment configuration is maintained in Git rather than changed
manually in a running cluster.

## Key Features

-   Automated CI pipeline using GitHub Actions.
-   Secret detection with Gitleaks.
-   Terraform security analysis with Checkov.
-   Docker image builds and vulnerability scanning with Trivy.
-   Helm chart linting and rendering for five services.
-   Kubernetes manifest security checks with Checkov.
-   AWS infrastructure defined using Terraform.
-   GitHub Actions authentication to AWS using OpenID Connect (OIDC),
    avoiding long-lived AWS access keys.
-   Private image repositories in Amazon ECR.
-   Kubernetes deployment on Amazon EKS using Helm.
-   GitOps-based synchronization through Argo CD.
-   Monitoring and observability configuration using Prometheus and
    Grafana.

## Architecture

``` mermaid
flowchart TB
    Developer[Developer] -->|Commit / Pull Request| GitHub[GitHub Repository]
    GitHub --> Actions[GitHub Actions CI/CD]

    subgraph CI[Continuous Integration and Security]
        Secrets[Gitleaks]
        IaC[Checkov: Terraform]
        HelmLint[Helm lint and template]
        Build[Build Docker images]
        ImageScan[Trivy image scan]
        K8sScan[Checkov: Kubernetes manifests]
        Secrets --> Gate[Validation and release decision]
        IaC --> Gate
        HelmLint --> Gate
        Build --> ImageScan --> Gate
        K8sScan --> Gate
    end

    Actions --> CI
    Gate -->|Successful checks| OIDC[GitHub OIDC authentication]
    OIDC --> ECR[Amazon ECR]
    Gate -->|Update image tag in Git| GitOps[GitOps configuration]
    GitOps --> Argo[Argo CD]
    ECR -->|Pull images| EKS[Amazon EKS]
    Argo -->|Sync Helm release| EKS
    EKS --> Services[UI · Catalog · Cart · Checkout · Orders]
    Services --> Monitoring[Prometheus and Grafana]
```

### Main components

  -----------------------------------------------------------------------
  Component                           Responsibility
  ----------------------------------- -----------------------------------
  GitHub                              Source control and pull request
                                      collaboration

  GitHub Actions                      Automates CI, security checks,
                                      image publishing, and GitOps
                                      updates

  Gitleaks                            Detects potential secrets in
                                      repository content

  Checkov                             Scans Terraform and rendered
                                      Kubernetes manifests

  Trivy                               Scans container images for known
                                      vulnerabilities

  Docker                              Packages each microservice into a
                                      container image

  Terraform                           Defines AWS network and Kubernetes
                                      infrastructure

  Amazon ECR                          Stores versioned container images

  Amazon EKS                          Runs the Kubernetes workloads

  Helm                                Packages Kubernetes resources into
                                      reusable charts

  Argo CD                             Reconciles the cluster with
                                      Git-managed desired state

  Prometheus and Grafana              Collect and visualize
                                      application/cluster metrics
  -----------------------------------------------------------------------

## End-to-End Workflow

The following sequence shows the intended release path from a code
change to a running application.

``` mermaid
sequenceDiagram
    autonumber
    participant Dev as Developer
    participant GH as GitHub
    participant CI as GitHub Actions
    participant Scan as Security Tools
    participant ECR as Amazon ECR
    participant GitOps as GitOps Configuration
    participant Argo as Argo CD
    participant EKS as Amazon EKS

    Dev->>GH: Push commit or open pull request
    GH->>CI: Trigger workflow
    CI->>Scan: Run Gitleaks, Checkov, Helm and Trivy
    Scan-->>CI: Return scan and validation results
    alt Checks pass
        CI->>CI: Build and tag service images
        CI->>ECR: Authenticate using OIDC and push images
        ECR-->>CI: Image digests and registry references
        CI->>GitOps: Update image tags in Git
        Argo->>GitOps: Detect desired-state change
        Argo->>EKS: Synchronize Helm release
        EKS-->>Argo: Report workload status
    else Checks fail
        CI-->>GH: Report failed check for review
    end
```

## Technology Stack

  Category                           Technologies
  ---------------------------------- -------------------------
  Source control                     Git, GitHub
  CI/CD automation                   GitHub Actions
  Containers                         Docker
  Secret scanning                    Gitleaks
  Infrastructure as Code             Terraform
  IaC and Kubernetes security        Checkov
  Container vulnerability scanning   Trivy
  Kubernetes packaging               Helm
  Container registry                 Amazon ECR
  Cloud platform                     AWS
  Kubernetes                         Amazon EKS
  Cloud authentication               GitHub OIDC and AWS IAM
  GitOps                             Argo CD
  Monitoring                         Prometheus, Grafana
  Scripting                          Bash

## Microservices

The platform contains five services, each built and deployed as an
independent container image with its own Helm chart.

  -------------------------------------------------------------------------------------
  Service           Purpose           Build context     Helm chart
  ----------------- ----------------- ----------------- -------------------------------
  UI                User-facing       `src/ui`          `src/ui/ui/chart`
                    application                         

  Catalog           Product catalog   `src/catalog`     `src/catalog/catalog/chart`

  Cart              Shopping cart     `src/cart`        `src/cart/cart/chart`

  Checkout          Checkout flow     `src/checkout`    `src/checkout/checkout/chart`

  Orders            Order management  `src/orders`      `src/orders/orders/chart`
  -------------------------------------------------------------------------------------

Each image is tagged with a version identifier such as the Git commit
SHA so that releases can be traced to source code. The deployed Helm
values reference the intended image tag.

## CI/CD Pipeline

The workflow is maintained in `.github/workflows/security-checks.yaml`
and is triggered by code changes and manual workflow dispatch.

### Pipeline stages

1.  **Checkout:** Retrieves the repository source.
2.  **Secret scanning:** Gitleaks looks for potential credentials or
    secrets.
3.  **Infrastructure scanning:** Checkov checks Terraform configuration
    against security policies.
4.  **Helm validation:** Lints and renders all five charts.
5.  **Image build:** Builds the five service images in CI.
6.  **Container scanning:** Trivy scans images for known
    vulnerabilities.
7.  **Kubernetes manifest scanning:** Checkov analyzes the rendered
    manifests.
8.  **AWS authentication:** GitHub Actions exchanges its OIDC identity
    for short-lived AWS credentials.
9.  **Image publishing:** Approved images are tagged and pushed to
    Amazon ECR.
10. **GitOps update:** The desired image tag is updated in Git.
11. **Deployment reconciliation:** Argo CD detects the change and
    synchronizes the Helm release to EKS.
12. **Post-deployment verification:** Workload health and deployment
    status are checked.

### Example CI flow

``` mermaid
flowchart TD
    A[Push or Pull Request] --> B[Gitleaks]
    B --> C[Terraform Checkov]
    C --> D[Helm lint and render]
    D --> E[Build service images]
    E --> F[Trivy scan]
    D --> G[Checkov Kubernetes scan]
    F --> H{Required checks pass?}
    G --> H
    H -->|No| I[Fail workflow and review findings]
    H -->|Yes| J[Authenticate to AWS using OIDC]
    J --> K[Push tagged images to ECR]
    K --> L[Update GitOps image tags]
    L --> M[Argo CD syncs EKS]
    M --> N[Verify rollout and health]
```

Security tools may report findings even when a workflow job is
configured with soft-fail behavior. A green job should be interpreted
together with its reports and the repository's release policy.

## Infrastructure as Code

Terraform is used to define the AWS infrastructure in a repeatable way.

The configuration covers:

-   **VPC:** Public and private subnets, routing, and network
    configuration.
-   **EKS:** Managed Kubernetes control plane and compute configuration.
-   **IAM:** Permissions required for cluster operations and CI
    publishing.
-   **OIDC trust:** Allows the intended GitHub Actions workflow to
    obtain temporary AWS credentials.
-   **ECR:** Container repositories for the five service images.
-   **Cluster add-ons:** Supporting components configured for the
    Kubernetes environment.
-   **Argo CD:** GitOps deployment tooling.

Infrastructure changes should be reviewed with a Terraform plan before
being applied. Only provision resources needed for the deployment, and
verify AWS costs and cleanup steps.

## GitOps Deployment

Argo CD uses Git as the source of truth for the application's desired
Kubernetes state.

``` mermaid
flowchart LR
    CI[CI publishes image] --> Tag[Image tag updated in Git]
    Tag --> Repo[GitOps repository/configuration]
    Repo --> Argo[Argo CD observes change]
    Argo --> Render[Helm chart rendered]
    Render --> Sync[Resources synchronized to EKS]
    Sync --> Health[Health and sync status]
    Health -->|Drift detected| Argo
```

This model separates responsibilities:

-   **CI** validates code and builds/publishes images.
-   **Git** records the desired image tags and deployment configuration.
-   **Argo CD** applies and reconciles that desired state.
-   **Kubernetes** runs the workloads and reports their status.

## Security Strategy

### Secrets management

-   Scan repository content with Gitleaks.
-   Use GitHub OIDC to access AWS with short-lived credentials.
-   Avoid long-lived AWS access keys in GitHub repository secrets.
-   Restrict IAM trust and permissions to the intended repository,
    branch, and workflow use case.
-   Rotate any credential that is accidentally exposed.

### Infrastructure security

-   Scan Terraform using Checkov.
-   Review public ingress rules and network boundaries.
-   Keep IAM permissions scoped to required resources and actions.
-   Review Terraform plans before provisioning or changing
    infrastructure.

### Container security

-   Scan container images with Trivy.
-   Review vulnerability severity, affected packages, and available
    fixes.
-   Prefer traceable image tags and immutable digests for deployment.
-   Rebuild images when base images or dependencies require security
    updates.

### Kubernetes security

-   Scan rendered Helm output with Checkov.
-   Use container security contexts and avoid unnecessary privileges.
-   Configure resource requests/limits and health probes.
-   Restrict service account permissions and network exposure to what
    the application requires.

## Monitoring and Observability

Prometheus and Grafana are included in the project's monitoring
configuration.

A typical observability path is:

``` mermaid
flowchart LR
    App[Application and cluster workloads] --> Metrics[Metrics endpoints / exporters]
    Metrics --> Prom[Prometheus]
    Prom --> Dashboards[Grafana dashboards]
    Prom --> Alerts[Alert rules]
```

Useful monitoring targets include pod health, restarts, CPU and memory
usage, request rates, error rates, and deployment status. Dashboard and
alert availability depends on the monitoring components being installed
and configured in the target cluster.

## Repository Structure

``` text
retail-platform/
├── .github/
│   └── workflows/
│       └── security-checks.yaml
├── argocd/
├── docs/
├── helm/
├── k8s/
├── monitoring/
├── terraform/
│   ├── addon.tf
│   ├── argocd.tf
│   ├── locals.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── security.tf
│   ├── variables.tf
│   └── versions.tf
└── src/
    ├── ui/
    ├── catalog/
    ├── cart/
    ├── checkout/
    └── orders/
```

## Prerequisites

For local validation:

-   Git
-   Docker
-   Helm
-   Terraform
-   Trivy
-   Checkov

For AWS deployment:

-   An AWS account with appropriate permissions and a reviewed budget.
-   AWS CLI configured for administrative setup and verification.
-   GitHub repository permissions to configure workflow settings.
-   Terraform variables configured for the target environment.
-   GitHub OIDC provider and least-privilege IAM role configured for the
    repository.
-   ECR repositories and EKS infrastructure provisioned.
-   Argo CD access to the GitOps configuration.

## Run Locally

Run commands from the repository root.

### Lint the Helm charts

``` bash
helm lint src/ui/ui/chart
helm lint src/catalog/catalog/chart
helm lint src/cart/cart/chart
helm lint src/checkout/checkout/chart
helm lint src/orders/orders/chart
```

### Render the charts

``` bash
mkdir -p rendered
helm template ui src/ui/ui/chart > rendered/ui.yaml
helm template catalog src/catalog/catalog/chart > rendered/catalog.yaml
helm template cart src/cart/cart/chart > rendered/cart.yaml
helm template checkout src/checkout/checkout/chart > rendered/checkout.yaml
helm template orders src/orders/orders/chart > rendered/orders.yaml
```

### Validate Terraform

``` bash
cd terraform
terraform init
terraform validate
terraform plan
```

Review the complete plan and cost implications before applying it.

### Build and scan an image

Example for the UI service:

``` bash
docker build -t retail-ui:local src/ui
trivy image --scanners vuln --severity HIGH,CRITICAL retail-ui:local
```

Docker must be running. Repeat with the appropriate build context for
each service.

## Deployment Overview

A typical deployment sequence is:

1.  Configure Terraform variables and review AWS permissions.
2.  Initialize and validate Terraform.
3.  Review the Terraform plan and estimated costs.
4.  Provision the required AWS resources.
5.  Configure GitHub OIDC trust and confirm the workflow can assume the
    intended IAM role.
6.  Build, scan, tag, and push service images to ECR.
7.  Update the GitOps configuration with the selected image tags.
8.  Confirm Argo CD synchronization and Kubernetes rollout health.
9.  Verify application connectivity, logs, and monitoring.
10. Tear down resources that are no longer required and verify that
    billable resources have been removed.

Exact commands depend on the final Terraform variables, cluster
settings, and repository configuration.

## Validation and Troubleshooting

  -----------------------------------------------------------------------
  Symptom                             What to check
  ----------------------------------- -----------------------------------
  Gitleaks reports a secret           Confirm whether it is a true
                                      secret; revoke exposed credentials
                                      and remove the secret safely from
                                      history where appropriate.

  Checkov reports findings            Read the rule ID and resource,
                                      assess the risk, and remediate or
                                      document an explicit exception.

  Docker build fails                  Check the service build context,
                                      Dockerfile, dependency downloads,
                                      and Docker daemon status.

  Trivy reports vulnerabilities       Identify the affected package and
                                      available patched version, rebuild,
                                      then rescan.

  Helm lint/render fails              Check chart templates,
                                      `values.yaml`, required values, and
                                      YAML indentation.

  GitHub OIDC role assumption fails   Check the repository/branch trust
                                      conditions, OIDC provider, role
                                      ARN, and IAM permissions.

  ECR push is denied                  Check repository URI, region,
                                      registry login, and push
                                      permissions.

  Argo CD does not deploy             Check repository access,
                                      application path, Helm values, sync
                                      status, and cluster health.

  Pods fail to start                  Inspect `kubectl get pods`,
                                      `kubectl describe pod`, and
                                      `kubectl logs`.
  -----------------------------------------------------------------------

## Lessons Learned

-   Security checks are most useful when included early in the delivery
    pipeline.
-   A successful CI run and a clean security report are different
    outcomes; findings must be reviewed.
-   Terraform makes infrastructure changes reviewable and repeatable.
-   OIDC reduces reliance on long-lived cloud credentials.
-   Immutable image identifiers improve traceability between code,
    image, and deployment.
-   GitOps reduces manual changes to the cluster and helps detect
    configuration drift.
-   Monitoring and rollout verification are essential after deployment,
    not just during CI.

## Future Improvements

Potential next enhancements include:

-   Enforce selected high-confidence security checks as required CI
    gates.
-   Generate and publish SBOMs for container images.
-   Sign images and verify signatures before deployment.
-   Add automated image vulnerability policy thresholds.
-   Add integration and smoke tests after deployment.
-   Add alert routing and service-level dashboards.
-   Add scheduled dependency updates and periodic image rebuilds.

## Acknowledgements

This project builds on a sample retail microservices application.
Preserve the upstream project's license and attribution requirements
when redistributing or modifying its code. The DevSecOps workflow,
infrastructure configuration, and deployment automation are portfolio
work built around that application.

------------------------------------------------------------------------

**Author:** Anushri Garg\
**Repository:**
[retail-platform](https://github.com/anushrigarg9/retail-platform)
