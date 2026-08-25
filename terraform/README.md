# Student Management — GCP / GKE Terraform

Terraform manages GCP infrastructure only. Jenkins and `kubectl` deploy Kubernetes workloads (PostgreSQL StatefulSet, backend, frontend, Gateway API). Terraform does **not** use a Kubernetes provider and does **not** apply application manifests.

## 1. Architecture

```text
Internet
   |
   v
GCP External Application Load Balancer
   |
   v
GKE Gateway (gke-l7-regional-external-managed)
   |
   +---------------------------+
   |                           |
   v                           v
frontend-service           backend-service
ClusterIP :80              ClusterIP :8080
   |                           |
   v                           v
Frontend Pods              Backend Pods
NGINX / React                  |
                               v
                    student-management-postgres
                    ClusterIP :5432
                               |
                               v
                    PostgreSQL StatefulSet (1 replica)
                               |
                               v
                    Persistent Disk (PVC)
```

Regional GKE Standard cluster:

```text
              gke-student-mgmt-<env>
                       |
         +-------------+-------------+
         |                           |
         v                           v
   us-central1-a               us-central1-b
     1 worker                    1 worker
```

## 2. Repository structure

```text
Student-Management/
├── backend/                 # Spring Boot 3.2.12, Java 17, port 8080
├── frontend/                # React/Vite, NGINX port 80
├── terraform/               # This directory
└── Jenkinsfile
```

Application ports and API paths come from the existing repository:

| Item | Value |
|------|--------|
| Backend port | `8080` (`application.properties` `server.port`) |
| Backend API | `/api/students` |
| Frontend container port | `80` |
| Database env vars | `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` |
| Local DB default | `studentdb` / `postgres` (unchanged for localhost) |
| GKE DB | `student_management` / `student_admin` |
| PostgreSQL version | `18` (from project README) |

## 3. Terraform modules

| Module | Responsibility |
|--------|----------------|
| `modules/project-services` | Enable GCP APIs (idempotent) |
| `modules/iam` | Least-privilege roles for `infra-admin` and the GKE node SA |
| `modules/network` | VPC `gke-vpc`, subnet `gke-subnet`, secondary ranges, proxy-only subnet |
| `modules/firewall` | Direct SSH TCP/22 and GCP health checks (not PostgreSQL) |
| `modules/artifact-registry` | Docker repo `student-management` |
| `modules/gke` | Regional Standard cluster + one node pool |

## 4. GCP APIs

Enabled (never disabled on destroy):

- `container.googleapis.com` (must exist before GKE)
- `compute.googleapis.com`
- `iam.googleapis.com`
- `iamcredentials.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `artifactregistry.googleapis.com`
- `logging.googleapis.com`
- `monitoring.googleapis.com`

## 5. IAM

Existing account: `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com`

Roles granted to infra-admin (no Owner/Editor):

- `roles/container.admin`
- `roles/compute.networkAdmin`
- `roles/compute.securityAdmin`
- `roles/artifactregistry.admin`
- `roles/iam.serviceAccountUser`
- `roles/iam.serviceAccountAdmin`
- `roles/serviceusage.serviceUsageAdmin`
- `roles/logging.configWriter`
- `roles/monitoring.editor`
- `roles/storage.objectAdmin`
- `roles/storage.admin` (create/configure the Terraform state bucket `gcp-dev-july-2026-terraform-state` before `terraform init`)

Node service account `gke-student-mgmt-nodes`:

- `roles/logging.logWriter`
- `roles/monitoring.metricWriter`
- `roles/monitoring.viewer`
- `roles/stackdriver.resourceMetadata.writer`
- `roles/artifactregistry.reader`

If apply fails with a missing permission: identify the exact permission, add only the matching predefined role, and document it here. No extra roles have been added beyond the list above yet.

## 6. VPC

- Name: `gke-vpc`
- `auto_create_subnetworks = false`

## 7. Subnet

- Name: `gke-subnet`
- Region: `us-central1`
- CIDR: `192.168.0.0/24`
- `private_ip_google_access = true`

## 8. Secondary ranges

VPC-native / IP alias:

| Range | Name | CIDR |
|-------|------|------|
| Pods | `gke-pods` | `192.168.16.0/20` |
| Services | `gke-services` | `192.168.32.0/20` |

Proxy-only subnet for regional Gateway (`REGIONAL_MANAGED_PROXY`): `192.168.48.0/23` (no overlap).

## 9. Firewall rules

| Rule | Protocol | Ports | Source | Target tag |
|------|----------|-------|--------|------------|
| `gke-student-mgmt-allow-ssh` | TCP | 22 | `ssh_source_ranges` | `gke-student-mgmt-ssh` |
| `gke-student-mgmt-allow-health-checks` | TCP | 80, 8080 | `130.211.0.0/22`, `35.191.0.0/16` | `gke-student-mgmt-web` |

There is **no** public TCP/5432 rule. PostgreSQL is ClusterIP-only.

IAP SSH is **not** configured. Do not use `--tunnel-through-iap`.

## 10. Direct SSH

Worker nodes receive tags `gke-student-mgmt-ssh` and `gke-student-mgmt-web` and have public IPs (cluster is not private-node).

```bash
gcloud compute instances list --filter="name~gke-student-mgmt"
gcloud compute ssh INSTANCE --zone=us-central1-a
# second node:
gcloud compute ssh INSTANCE --zone=us-central1-b
```

`ssh_source_ranges` is per environment. Dev example: `["0.0.0.0/0"]`. Restrict QA/PROD to a trusted CIDR in `environments/*.tfvars` — do not silently change it in Terraform modules.

## 11. GKE

- Standard regional cluster (not Autopilot)
- Names: `gke-student-mgmt-dev` / `-qa` / `-prod`
- Network `gke-vpc`, subnet `gke-subnet`
- Workload Identity, Cloud Logging, Cloud Monitoring
- Gateway API channel: `CHANNEL_STANDARD`

## 12. Exactly 2 nodes

`node_count` is the **total** worker count (default `2`).

GKE regional node pools are **per zone**. This module sets:

`per-zone count = node_count / length(node_locations)`

With two zones that is `1 + 1 = 2`. Autoscaling is omitted (disabled). There is one node pool only.

## 13. Node distribution

- `us-central1-a` = 1
- `us-central1-b` = 1
- No third zone

Verify: `kubectl get nodes -o wide`

## 14. GKE node OS

Image type: `UBUNTU_CONTAINERD` (Ubuntu with containerd).

This is the currently supported GKE Ubuntu node image. Ubuntu 26.04 LTS Minimal is **not** used. No custom Compute Engine images.

Release channel is configurable (`REGULAR` in dev/qa, `STABLE` in prod). GKE selects the supported Ubuntu containerd image for that channel/version.

## 15. Artifact Registry

- Repository ID: `student-management`
- Location: `us-central1`
- Format: Docker

Images (never `latest`):

```text
us-central1-docker.pkg.dev/gcp-dev-july-2026/student-management/student-management-backend:${IMAGE_TAG}
us-central1-docker.pkg.dev/gcp-dev-july-2026/student-management/student-management-frontend:${IMAGE_TAG}
```

`IMAGE_TAG` is the Jenkins `BUILD_NUMBER` unless overridden.

## 16. PostgreSQL StatefulSet

- Name: `student-management-postgres`
- Namespace: `student-management`
- Image: `postgres:18`
- Replicas: `1`
- Probes: `pg_isready`
- Deployed by Jenkins/`kubectl`, not Terraform

## 17. PostgreSQL PVC

- Name: `student-management-postgres-pvc`
- Access: `ReadWriteOnce`
- Default size: `10Gi`
- Mount: `/var/lib/postgresql/data` (`PGDATA=.../pgdata`)
- Storage class: `standard-rwo`
- Not `emptyDir`

## 18. PostgreSQL Service

- Name: `student-management-postgres`
- Type: `ClusterIP`
- Port: `5432`
- Not LoadBalancer, NodePort, Gateway, or Ingress

## 19. Backend

Existing `backend/Dockerfile`. Deployment `backend`, Service `backend-service` (ClusterIP :8080).

Connection:

```text
DB_HOST=student-management-postgres
DB_PORT=5432
DB_NAME=student_management
DB_USERNAME=student_admin
DB_PASSWORD=<Kubernetes Secret>
```

JDBC URL becomes `student-management-postgres:5432`. Not `localhost` / `127.0.0.1`.

## 20. Frontend

Existing `frontend/Dockerfile` plus build-arg `VITE_API_BASE_URL=/api` so the browser calls the Gateway path `/api` (same origin). Service `frontend-service` ClusterIP :80.

## 21. GKE Gateway API

Community `ingress-nginx` is not used. Traffic uses GKE Gateway API.

## 22. Gateway

- GatewayClass (GKE-managed, verified before use): `gke-l7-regional-external-managed`
- Gateway: `student-management-gateway`
- HTTP listener port 80
- HTTPS 443 is omitted until TLS is configured

## 23. HTTPRoute

- Name: `student-management-route`
- `/api` → `backend-service:8080`
- `/` → `frontend-service:80`

## 24. Jenkins

- URL: `http://localhost:8090/`
- Job: `student-management-gke-pipeline`
- Root `Jenkinsfile`

Parameters: `ACTION` (`plan`/`apply`/`destroy`), `ENVIRONMENT` (`dev`/`qa`/`prod`), `IMAGE_TAG`, `TERRAFORM_VERSION` (`1.13.x`).

## 25. Jenkins credential

Secret file credential ID: `gcp-infra-admin-json`  
JSON key for `infra-admin@...` — never commit it.

Optional string credential: `student-management-postgres-password` (injected into Kubernetes Secrets).

## 26. Pipeline phases

| Phase | What | GCP changes? |
|-------|------|----------------|
| 1 | Tests, Maven package, npm build, Docker builds | No |
| 2 | `terraform fmt/validate/plan` | No |
| 3 | `terraform apply`, push images, kubectl deploy | Yes |

`ACTION=plan` runs Phase 1 + 2 only.  
`ACTION=apply` runs 1 → 2 → 3.  
`ACTION=destroy` skips builds and requires approval (and always shows a destroy plan first).  
Prod apply requires: `Approve PRODUCTION infrastructure deployment?`

If any phase fails, stop. Do not continue, commit, or open a PR from a failed run.

## 27. Environment configuration

Use only:

- `terraform/environments/dev.tfvars`
- `terraform/environments/qa.tfvars`
- `terraform/environments/prod.tfvars`

Do **not** create `terraform.tfvars`. Do not put passwords, private keys, SA JSON, or tokens in tfvars.

GCS backend (create the bucket once via `terraform/bootstrap`):

| Env | Bucket | Prefix |
|-----|--------|--------|
| DEV | `gcp-dev-july-2026-terraform-state` | `gke/dev` |
| QA | `gcp-dev-july-2026-terraform-state` | `gke/qa` |
| PROD | `gcp-dev-july-2026-terraform-state` | `gke/prod` |

These environment files share VPC/subnet/Artifact Registry names in the same project. Apply **one** environment at a time unless you split projects or rename networks.

## 28. Deployment

Bootstrap (once):

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Dev plan:

```bash
cd terraform
terraform init -backend-config=backend/dev.tfbackend
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=environments/dev.tfvars
```

Kubernetes order (Jenkins Phase 3):

1. Namespace  
2. PostgreSQL Secret  
3. PVC  
4. StatefulSet  
5. Service  
6. Wait Ready  
7. Backend Secret/ConfigMap  
8. Backend Deployment/Service  
9. Frontend Deployment/Service  
10. GatewayClass (verify GKE class)  
11. Gateway  
12. HTTPRoute  

## 29. Verification

```bash
kubectl get nodes -o wide
kubectl get statefulset,pods,pvc,svc -n student-management
kubectl get gatewayclass
kubectl get gateway,httproute -n student-management
```

Expect two Ready nodes, postgres-0 Ready, PVC Bound, all app Services ClusterIP, Gateway address present.

```bash
curl http://<GATEWAY-IP>/
curl http://<GATEWAY-IP>/api/students
```

## 30. Database persistence

1. Insert a student through the API.  
2. `kubectl -n student-management delete pod student-management-postgres-0`  
3. Wait until Ready.  
4. Confirm the row still exists. Do **not** delete the PVC.

## 31. Rollback

- Application: deploy a previous immutable `IMAGE_TAG`.  
- Infrastructure: `terraform apply` a previous plan or `git revert` then apply.  
- Do not use `latest`.

## 32. Destroy

```bash
terraform init -backend-config=backend/<env>.tfbackend
terraform plan -destroy -var-file=environments/<env>.tfvars
terraform apply -destroy -var-file=environments/<env>.tfvars
```

Jenkins `ACTION=destroy` shows the destroy plan and requires approval. It does not build or push images. Kubernetes objects in a deleted cluster are removed with the cluster; the GCS state bucket from bootstrap is **not** destroyed by the main stack.

## 33. Troubleshooting

| Symptom | Check |
|---------|--------|
| API enablement race | `container.googleapis.com` must be enabled; module depends_on is set |
| 4 worker nodes | You set GKE `node_count` per zone to 2; this repo uses total=2 → 1 per zone |
| Gateway no IP | Proxy-only subnet `192.168.48.0/23` must exist; wait for `Programmed` |
| Backend never Ready | Postgres Ready first; `DB_HOST=student-management-postgres` |
| Frontend Network Error | Image must be built with `VITE_API_BASE_URL=/api` |
| SSH timeout | Firewall `gke-student-mgmt-allow-ssh`, tag `gke-student-mgmt-ssh`, no IAP |
| Permission denied on apply | Add only the missing IAM role and document it in section 5 |
| `fmt` fails | `terraform fmt -recursive` |
| `storage: bucket doesn't exist` | Jenkins must create `gcp-dev-july-2026-terraform-state` before `terraform init`. Grant `infra-admin` `roles/storage.admin` if bucket create returns 403. |

## Outputs

`project_id`, `network_name`, `subnet_name`, `subnet_cidr`, `pods_secondary_range`, `services_secondary_range`, `cluster_name`, `cluster_region`, `cluster_zones`, `node_pool_name`, `node_count`, `artifact_registry_repository`.

Secrets, keys, and tokens are never outputted.
