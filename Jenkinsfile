pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  parameters {
    choice(name: 'ACTION', choices: ['APPLY', 'DESTROY'], description: 'Terraform action. APPLY and DESTROY both require Jenkins approval.')
    choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Target environment (dev.tfvars / qa.tfvars / prod.tfvars)')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Immutable image tag. Defaults to BUILD_NUMBER. Never use latest.')
    string(name: 'TERRAFORM_VERSION', defaultValue: '1.13.5', description: 'Terraform 1.13.x')
    string(name: 'GCP_PROJECT_ID', defaultValue: 'gcp-dev-july-2026', description: 'GCP project')
    string(name: 'GCP_REGION', defaultValue: 'us-central1', description: 'GCP region')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = '0'
    GODEBUG = 'tlsmlkem=0,tlskyber=0,http2client=0'
    JAVA_HOME = '/opt/java/openjdk'
    MAVEN_HOME = '/opt/maven'
    TF_STATE_BUCKET = 'gcp-dev-july-2026-terraform-state'
    K8S_DIR = 'terraform/kubernetes'
    AR_HOST = 'us-central1-docker.pkg.dev'
    AR_REPO = 'us-central1-docker.pkg.dev/gcp-dev-july-2026/student-management'
  }

  stages {
    stage('Checkout Source') {
      steps {
        checkout scm
        script {
          if (!params.ACTION?.trim()) { error('ACTION is required') }
          if (!(params.ENVIRONMENT in ['dev', 'qa', 'prod'])) { error('ENVIRONMENT must be dev, qa, or prod') }
          if (!(params.ACTION in ['APPLY', 'DESTROY'])) { error('ACTION must be APPLY or DESTROY') }
          env.IMAGE_TAG = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : "${env.BUILD_NUMBER}"
          if (env.IMAGE_TAG == 'latest') { error('IMAGE_TAG must not be latest') }
          env.CLUSTER_NAME = "gke-student-mgmt-${params.ENVIRONMENT}"
          env.TF_VAR_FILE = "environments/${params.ENVIRONMENT}.tfvars"
          env.TF_BACKEND_FILE = "backend/${params.ENVIRONMENT}.tfbackend"
          echo "ACTION=${params.ACTION} ENVIRONMENT=${params.ENVIRONMENT} IMAGE_TAG=${env.IMAGE_TAG} CLUSTER=${env.CLUSTER_NAME} TF_VAR_FILE=${env.TF_VAR_FILE}"
        }
      }
    }

    stage('Build & Test') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        sh '''
          set -euo pipefail
          echo "JAVA_HOME=${JAVA_HOME:-}"
          JAVA_VERSION=$(java -version 2>&1 | head -n 1)
          echo "Detected Java: ${JAVA_VERSION}"
          echo "${JAVA_VERSION}" | grep -q 'version "17' || {
            echo "ERROR: Java 17 is required"
            exit 1
          }
        '''
        sh '''
          set -euo pipefail
          MVN_VERSION=$(mvn -version | head -n 1)
          echo "Detected Maven: ${MVN_VERSION}"
          echo "${MVN_VERSION}" | grep -q "Apache Maven 3.5.4" || {
            echo "ERROR: Apache Maven 3.5.4 is required"
            exit 1
          }
          MVN_JAVA=$(mvn -version | grep "Java version:" | head -n 1)
          echo "Detected Maven Java: ${MVN_JAVA}"
          echo "${MVN_JAVA}" | grep -q "Java version: 17" || {
            echo "ERROR: Maven must run on Java 17"
            exit 1
          }
        '''
        dir('backend') {
          sh '''
            set -euo pipefail
            mvn -B clean test package
          '''
        }
        dir('frontend') {
          sh '''
            set -euo pipefail
            npm ci
            npm run lint
            npm run build
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('terraform') {
          sh '''
            set -euo pipefail
            terraform fmt -check -recursive
          '''
        }
        withCredentials([
          file(
            credentialsId: 'gcp-infra-admin',
            variable: 'GOOGLE_APPLICATION_CREDENTIALS'
          )
        ]) {
          sh '''
            set -euo pipefail

            PROJECT="gcp-dev-july-2026"
            BUCKET="gcp-dev-july-2026-terraform-state"
            REGION="us-central1"

            echo "========================================"
            echo "Terraform State Bucket"
            echo "========================================"

            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
            gcloud config set project "${PROJECT}"

            echo "Enabling Cloud Storage API..."
            gcloud services enable storage.googleapis.com --project="${PROJECT}"

            if gcloud storage buckets describe "gs://${BUCKET}" --project="${PROJECT}" >/dev/null 2>&1; then
              echo "Terraform state bucket already exists."
            else
              echo "Creating Terraform state bucket..."
              gcloud storage buckets create "gs://${BUCKET}" \
                --project="${PROJECT}" \
                --location="${REGION}" \
                --uniform-bucket-level-access \
                --pap
            fi

            echo "Validating bucket configuration..."

            LOCATION="$(
              gcloud storage buckets describe "gs://${BUCKET}" \
                --project="${PROJECT}" \
                --format='value(location)' | tr '[:upper:]' '[:lower:]'
            )"
            echo "location=${LOCATION}"
            if [ -z "${LOCATION}" ]; then
              echo "ERROR: Unable to determine bucket location."
              exit 1
            fi
            if [ "${LOCATION}" != "${REGION}" ]; then
              echo "ERROR: Expected location=${REGION}"
              echo "Actual location=${LOCATION}"
              exit 1
            fi

            UNIFORM_BUCKET_LEVEL_ACCESS="$(
              gcloud storage buckets describe "gs://${BUCKET}" \
                --project="${PROJECT}" \
                --format='value(uniform_bucket_level_access)'
            )"
            echo "uniform_bucket_level_access=${UNIFORM_BUCKET_LEVEL_ACCESS}"
            if [ -z "${UNIFORM_BUCKET_LEVEL_ACCESS}" ]; then
              echo "ERROR: Could not determine Uniform Bucket-Level Access."
              exit 1
            fi
            case "${UNIFORM_BUCKET_LEVEL_ACCESS}" in
              True|true)
                echo "UNIFORM_BUCKET_LEVEL_ACCESS=ENABLED"
                ;;
              *)
                echo "ERROR: Uniform Bucket-Level Access must be enabled."
                echo "Actual=${UNIFORM_BUCKET_LEVEL_ACCESS}"
                exit 1
                ;;
            esac

            PUBLIC_ACCESS_PREVENTION="$(
              gcloud storage buckets describe "gs://${BUCKET}" \
                --project="${PROJECT}" \
                --format='value(public_access_prevention)' | tr '[:upper:]' '[:lower:]'
            )"
            echo "public_access_prevention=${PUBLIC_ACCESS_PREVENTION}"
            if [ -z "${PUBLIC_ACCESS_PREVENTION}" ]; then
              echo "ERROR: Could not determine Public Access Prevention."
              exit 1
            fi
            if [ "${PUBLIC_ACCESS_PREVENTION}" != "enforced" ]; then
              echo "ERROR: Public Access Prevention must be enforced."
              echo "Actual=${PUBLIC_ACCESS_PREVENTION}"
              exit 1
            fi
            echo "PUBLIC_ACCESS_PREVENTION=ENFORCED"

            echo "Terraform state bucket validation completed."
          '''
          dir('terraform') {
            sh '''
              set -euo pipefail
              TFV="${TERRAFORM_VERSION}"
              case "${TFV}" in
                1.13.*) ;;
                *) echo "TERRAFORM_VERSION must be 1.13.x" >&2; exit 1 ;;
              esac
              TF_OUT=$(terraform version)
              printf '%s\n' "${TF_OUT}"
              TF_LINE=$(printf '%s\n' "${TF_OUT}" | sed -n '1p')
              echo "Detected Terraform: ${TF_LINE}"
              if [ "${TF_LINE}" != "Terraform v${TFV}" ]; then
                echo "ERROR: Terraform v${TFV} is required (detected: ${TF_LINE})" >&2
                exit 1
              fi
              echo "Terraform version validation successful."
              terraform init -input=false -reconfigure -backend-config="${TF_BACKEND_FILE}"
              terraform validate
              if [ "${ACTION}" = "DESTROY" ]; then
                terraform plan -destroy -input=false -var-file="${TF_VAR_FILE}"
              else
                terraform plan -input=false -var-file="${TF_VAR_FILE}"
              fi
            '''
          }
        }
      }
    }

    stage('Approve Terraform Apply') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        script {
          timeout(time: 30, unit: 'MINUTES') {
            input(
              message: """Terraform Apply requires manual approval. This will create/update GCP infrastructure.

Approve Terraform Apply for gcp-dev-july-2026?

Environment:
${params.ENVIRONMENT}""",
              ok: 'Proceed'
            )
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform apply -input=false -auto-approve -var-file="${TF_VAR_FILE}"
            '''
          }
        }
      }
    }

    stage('Docker Build & Push') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        sh '''
          set -euo pipefail
          docker version
        '''
        withCredentials([
          file(
            credentialsId: 'gcp-infra-admin',
            variable: 'GOOGLE_APPLICATION_CREDENTIALS'
          )
        ]) {
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
            gcloud config set project gcp-dev-july-2026
            test -f backend/Dockerfile || {
              echo "ERROR: expected existing Dockerfile at backend/Dockerfile" >&2
              exit 1
            }
            test -f frontend/Dockerfile || {
              echo "ERROR: expected existing Dockerfile at frontend/Dockerfile" >&2
              exit 1
            }
            gcloud artifacts repositories describe student-management \
              --location=us-central1 \
              --project=gcp-dev-july-2026
            gcloud auth configure-docker "${AR_HOST}" --quiet
            if ! docker buildx inspect student-mgmt-ar >/dev/null 2>&1; then
              docker buildx create --name student-mgmt-ar --driver docker-container \
                --driver-opt env.GODEBUG=tlsmlkem=0
            fi
            docker buildx inspect student-mgmt-ar --bootstrap
            docker buildx build \
              --builder student-mgmt-ar \
              --push \
              --provenance=false \
              --sbom=false \
              -f backend/Dockerfile \
              -t "${AR_REPO}/student-management-backend:${IMAGE_TAG}" \
              backend
            docker buildx build \
              --builder student-mgmt-ar \
              --push \
              --provenance=false \
              --sbom=false \
              --build-arg VITE_API_BASE_URL=/api \
              -f frontend/Dockerfile \
              -t "${AR_REPO}/student-management-frontend:${IMAGE_TAG}" \
              frontend
          '''
        }
      }
    }

    stage('Deploy Application') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
            gcloud config set project gcp-dev-july-2026
            gcloud container clusters get-credentials "${CLUSTER_NAME}" \
              --region="${GCP_REGION}" \
              --project="${GCP_PROJECT_ID}"
            kubectl get nodes -o wide
          '''
        }
        sh 'kubectl apply -f "${K8S_DIR}/namespace.yaml"'
        sh '''
          set -euo pipefail
          if ! kubectl -n student-management get secret student-management-postgres-secret >/dev/null 2>&1; then
            POSTGRES_PASSWORD="$(head -c 32 /dev/urandom | base64 | tr -d '\n')"
            kubectl -n student-management create secret generic student-management-postgres-secret \
              --from-literal=POSTGRES_DB=student_management \
              --from-literal=POSTGRES_USER=student_admin \
              --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
            unset POSTGRES_PASSWORD
          fi
          kubectl apply -f "${K8S_DIR}/postgres-pvc.yaml"
          kubectl apply -f "${K8S_DIR}/postgres-statefulset.yaml"
          kubectl apply -f "${K8S_DIR}/postgres-service.yaml"
        '''
        sh '''
          set -euo pipefail
          kubectl -n student-management rollout status statefulset/student-management-postgres --timeout=300s
          kubectl wait --for=condition=Ready pod/student-management-postgres-0 -n student-management --timeout=300s
        '''
        sh '''
          set -euo pipefail
          kubectl apply -f "${K8S_DIR}/configmap.yaml"
          DB_PASSWORD="$(kubectl -n student-management get secret student-management-postgres-secret \
            -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
          test -n "${DB_PASSWORD}" || {
            echo "ERROR: PostgreSQL secret student-management-postgres-secret is missing POSTGRES_PASSWORD" >&2
            exit 1
          }
          kubectl -n student-management create secret generic student-management-backend-secret \
            --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
            --dry-run=client -o yaml | kubectl apply -f -
          unset DB_PASSWORD
          sed "s|:PLACEHOLDER|:${IMAGE_TAG}|g" "${K8S_DIR}/backend-deployment.yaml" | kubectl apply -f -
          kubectl apply -f "${K8S_DIR}/backend-service.yaml"
          kubectl -n student-management rollout status deployment/backend --timeout=300s
        '''
        sh '''
          set -euo pipefail
          sed "s|:PLACEHOLDER|:${IMAGE_TAG}|g" "${K8S_DIR}/frontend-deployment.yaml" | kubectl apply -f -
          kubectl apply -f "${K8S_DIR}/frontend-service.yaml"
          kubectl -n student-management rollout status deployment/frontend --timeout=300s
        '''
        sh '''
          set -euo pipefail
          if ! kubectl get gatewayclass gke-l7-regional-external-managed >/dev/null 2>&1; then
            kubectl apply -f "${K8S_DIR}/gateway-class.yaml"
          fi
          kubectl apply -f "${K8S_DIR}/gateway.yaml"
          kubectl apply -f "${K8S_DIR}/healthcheck-policies.yaml"
        '''
        sh 'kubectl apply -f "${K8S_DIR}/http-route.yaml"'
      }
    }

    stage('Deployment Verification') {
      when { expression { params.ACTION == 'APPLY' } }
      steps {
        sh '''
          set -euo pipefail
          kubectl get nodes -o wide
          NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d " ")
          if [ "${NODE_COUNT}" != "2" ]; then
            echo "Expected exactly 2 worker nodes, found ${NODE_COUNT}" >&2
            exit 1
          fi
        '''
        sh '''
          set -euo pipefail
          kubectl get statefulset -n student-management
          kubectl get pods -n student-management
          kubectl get pvc -n student-management
          kubectl get svc -n student-management
        '''
        sh '''
          set -euo pipefail
          for svc in frontend-service backend-service student-management-postgres; do
            TYPE=$(kubectl -n student-management get svc "${svc}" -o jsonpath="{.spec.type}")
            echo "${svc} type=${TYPE}"
            if [ "${TYPE}" != "ClusterIP" ]; then
              echo "${svc} must be ClusterIP" >&2
              exit 1
            fi
          done
        '''
        sh '''
          set -euo pipefail
          kubectl get gatewayclass
          kubectl get gateway -n student-management
          kubectl get httproute -n student-management
          for i in $(seq 1 60); do
            IP=$(kubectl -n student-management get gateway student-management-gateway \
              -o jsonpath="{.status.addresses[0].value}" 2>/dev/null || true)
            if [ -n "${IP}" ]; then
              echo "Gateway address=${IP}"
              echo "${IP}" > "${WORKSPACE}/gateway-ip.txt"
              break
            fi
            echo "Waiting for Gateway address (${i}/60)..."
            sleep 10
            if [ "${i}" = "60" ]; then
              echo "Gateway did not receive an address" >&2
              kubectl -n student-management describe gateway student-management-gateway
              exit 1
            fi
          done
        '''
        sh '''
          set -euo pipefail
          IP=$(cat "${WORKSPACE}/gateway-ip.txt")
          test -n "${IP}" || {
            echo "ERROR: Gateway IP is empty. Deployment verification cannot continue." >&2
            exit 1
          }
          FRONTEND_URL="http://${IP}/"
          BACKEND_URL="http://${IP}/api/students"

          echo "=================================================="
          echo "DEPLOYMENT VERIFICATION"
          echo "=================================================="
          echo "Frontend Endpoint:"
          echo "${FRONTEND_URL}"
          echo "Backend Endpoint:"
          echo "${BACKEND_URL}"
          echo "=================================================="

          max=36
          delay=10
          for url in "${FRONTEND_URL}" "${BACKEND_URL}"; do
            ready=0
            i=1
            while [ "${i}" -le "${max}" ]; do
              set +e
              http_code=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 20 "${url}")
              curl_rc=$?
              set -e
              if [ "${curl_rc}" -eq 0 ] && [ "${http_code}" = "200" ]; then
                echo "${url} ready: HTTP ${http_code}"
                ready=1
                break
              fi
              if [ "${curl_rc}" -ne 0 ]; then
                echo "${url} not ready (${i}/${max}): connection/timeout curl_rc=${curl_rc}"
              else
                echo "${url} not ready (${i}/${max}): HTTP ${http_code}"
              fi
              i=$((i + 1))
              sleep "${delay}"
            done
            if [ "${ready}" -ne 1 ]; then
              echo "ERROR: ${url} did not return HTTP 200 within $((max * delay))s" >&2
              exit 1
            fi
          done

          echo "Frontend verification: ${FRONTEND_URL}"
          curl -fsS --connect-timeout 5 --max-time 20 "${FRONTEND_URL}" | dd bs=1 count=200 2>/dev/null
          echo
          echo "Frontend verification: SUCCESS"

          echo "Backend verification: ${BACKEND_URL}"
          curl -fsS --connect-timeout 5 --max-time 20 "${BACKEND_URL}"
          echo
          echo "Backend verification: SUCCESS"
          echo "=================================================="
          echo "DEPLOYMENT VERIFICATION PASSED"
          echo "=================================================="
        '''
      }
    }

    stage('Approve Terraform Destroy') {
      when { expression { params.ACTION == 'DESTROY' } }
      steps {
        script {
          timeout(time: 30, unit: 'MINUTES') {
            input(
              message: """WARNING: Terraform Destroy will permanently delete the deployed GCP infrastructure. This action is destructive and cannot be automatically reversed.

WARNING: Approve Terraform Destroy for gcp-dev-july-2026? This will permanently delete infrastructure.

Environment:
${params.ENVIRONMENT}""",
              ok: 'Proceed'
            )
          }
        }
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'DESTROY' } }
      steps {
        withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
            gcloud config set project gcp-dev-july-2026
            cluster_present=0
            if gcloud container clusters describe "${CLUSTER_NAME}" \
                 --region="${GCP_REGION}" \
                 --project="${GCP_PROJECT_ID}" >/dev/null 2>&1; then
              cluster_present=1
              gcloud container clusters get-credentials "${CLUSTER_NAME}" \
                --region="${GCP_REGION}" \
                --project="${GCP_PROJECT_ID}"
              kubectl delete httproute student-management-route -n student-management --ignore-not-found --wait=true --timeout=180s
              kubectl delete gateway student-management-gateway -n student-management --ignore-not-found --wait=true --timeout=180s
              kubectl delete healthcheckpolicy --all -n student-management --ignore-not-found --wait=true --timeout=180s
              kubectl delete svc backend-service frontend-service -n student-management --ignore-not-found --wait=true --timeout=180s
              kubectl delete namespace student-management --ignore-not-found --wait=true --timeout=300s
            else
              echo "GKE cluster ${CLUSTER_NAME} is not present; skipping Kubernetes Gateway cleanup."
            fi
            released=0
            i=1
            max=36
            while [ "${i}" -le "${max}" ]; do
              neg_list="$(gcloud compute network-endpoint-groups list \
                --project=gcp-dev-july-2026 \
                --filter="name~k8s1- AND name~student-management" \
                --format="value(name)")"
              if [ -z "${neg_list}" ]; then
                echo "GKE-managed NEGs released from gke-vpc."
                released=1
                break
              fi
              echo "Waiting for GKE-managed NEGs to detach (${i}/${max}):"
              echo "${neg_list}"
              i=$((i + 1))
              sleep 10
            done
            if [ "${released}" -ne 1 ]; then
              gcloud compute network-endpoint-groups list \
                --project=gcp-dev-july-2026 \
                --filter="name~k8s1- AND name~student-management" \
                --format="table(name,zone,network)" >&2
              if [ "${cluster_present}" = "1" ]; then
                echo "ERROR: GKE-managed NEGs still using gke-vpc after Gateway cleanup." >&2
                exit 1
              fi
              echo "WARNING: GKE-managed NEGs still present and the cluster is gone. Terraform VPC delete will retry."
            fi
          '''
          dir('terraform') {
            sh '''
              set -euo pipefail
              terraform destroy -input=false -auto-approve -var-file="${TF_VAR_FILE}"
            '''
          }
          sh '''
            set -euo pipefail
            gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
            gcloud config set project gcp-dev-july-2026
            echo "Destroy completed. Remaining GKE clusters (filter=${CLUSTER_NAME}):"
            gcloud container clusters list \
              --project=gcp-dev-july-2026 \
              --filter="name=${CLUSTER_NAME}" \
              --format="table(name,location,status)" || true
          '''
        }
      }
    }
  }

  post {
    failure {
      echo 'A previous stage failed. The first ERROR / non-zero shell status above this line is the actual cause.'
      echo 'Pipeline failed. Stop here. Do not continue to later phases, commit, or open a PR from a failed run.'
    }
  }
}
