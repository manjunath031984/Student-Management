pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Pipeline action')
    choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Target environment')
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Immutable image tag. Defaults to BUILD_NUMBER. Never use latest.')
    string(name: 'TERRAFORM_VERSION', defaultValue: '1.13.5', description: 'Terraform 1.13.x')
    string(name: 'GCP_PROJECT_ID', defaultValue: 'gcp-dev-july-2026', description: 'GCP project')
    string(name: 'GCP_REGION', defaultValue: 'us-central1', description: 'GCP region')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = '0'
    JAVA_HOME = '/opt/java/openjdk'
    MAVEN_HOME = '/opt/maven'
    TF_STATE_BUCKET = 'gcp-dev-july-2026-terraform-state'
    K8S_DIR = 'terraform/kubernetes'
    AR_HOST = 'us-central1-docker.pkg.dev'
    AR_REPO = 'us-central1-docker.pkg.dev/gcp-dev-july-2026/student-management'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Validate Parameters') {
      steps {
        script {
          if (!params.ACTION?.trim()) { error('ACTION is required') }
          if (!(params.ENVIRONMENT in ['dev', 'qa', 'prod'])) { error('ENVIRONMENT must be dev, qa, or prod') }
          if (!(params.ACTION in ['plan', 'apply', 'destroy'])) { error('ACTION must be plan, apply, or destroy') }
          env.IMAGE_TAG = params.IMAGE_TAG?.trim() ? params.IMAGE_TAG.trim() : "${env.BUILD_NUMBER}"
          if (env.IMAGE_TAG == 'latest') { error('IMAGE_TAG must not be latest') }
          env.CLUSTER_NAME = "gke-student-mgmt-${params.ENVIRONMENT}"
          env.TF_VAR_FILE = "environments/${params.ENVIRONMENT}.tfvars"
          env.TF_BACKEND_FILE = "backend/${params.ENVIRONMENT}.tfbackend"
          echo "ACTION=${params.ACTION} ENVIRONMENT=${params.ENVIRONMENT} IMAGE_TAG=${env.IMAGE_TAG} CLUSTER=${env.CLUSTER_NAME}"
        }
      }
    }

    stage('GCP Authentication') {
      steps {
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
          '''
        }
      }
    }

    stage('Java Validation') {
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
      }
    }

    stage('Maven Validation') {
      steps {
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
      }
    }

    stage('Docker Validation') {
      steps {
        sh '''
          set -euo pipefail
          docker --version
          docker info
        '''
      }
    }

    stage('Application Validation') {
      when { expression { params.ACTION != 'destroy' } }
      steps {
        dir('backend') {
          sh '''
            set -euo pipefail
            java -version
            mvn -version
            mvn -B clean test
            mvn -B clean package
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

    stage('Container Image Build') {
      when { expression { params.ACTION != 'destroy' } }
      steps {
        sh '''
          set -euo pipefail
          docker build -t "${AR_REPO}/student-management-backend:${IMAGE_TAG}" backend
          docker build --build-arg VITE_API_BASE_URL=/api \
            -t "${AR_REPO}/student-management-frontend:${IMAGE_TAG}" frontend
        '''
      }
    }

    stage('Verify Terraform') {
      steps {
        sh '''
          set -euo pipefail
          TFV="${TERRAFORM_VERSION}"
          case "${TFV}" in
            1.13.*) ;;
            *) echo "TERRAFORM_VERSION must be 1.13.x" >&2; exit 1 ;;
          esac
          terraform version
          TF_LINE=$(terraform version | head -n 1)
          echo "Detected Terraform: ${TF_LINE}"
          echo "${TF_LINE}" | grep -q "Terraform v1.13" || {
            echo "ERROR: Terraform 1.13.x is required"
            exit 1
          }
        '''
      }
    }

    stage('Terraform Code Validation') {
      when { expression { params.ACTION != 'destroy' } }
      steps {
        dir('terraform') {
          sh '''
            set -euo pipefail
            terraform fmt -check -recursive
          '''
        }
      }
    }

    stage('Terraform State Bucket') {
      steps {
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
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform init -input=false -reconfigure -backend-config="${TF_BACKEND_FILE}"
              terraform validate
            '''
          }
        }
      }
    }

    stage('Terraform Plan') {
      when { expression { params.ACTION == 'plan' || params.ACTION == 'apply' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform plan -input=false -var-file="${TF_VAR_FILE}" -out=tfplan
            '''
          }
        }
      }
    }

    stage('Manual Approval') {
      when {
        anyOf {
          expression { params.ACTION == 'apply' && params.ENVIRONMENT == 'prod' }
          expression { params.ACTION == 'destroy' }
        }
      }
      steps {
        script {
          def msg = params.ACTION == 'destroy'
            ? "Approve ${params.ENVIRONMENT.toUpperCase()} Terraform DESTROY? This deletes GKE and related GCP infrastructure."
            : 'Approve PRODUCTION infrastructure deployment?'
          timeout(time: 30, unit: 'MINUTES') {
            input message: msg
          }
        }
      }
    }

    stage('Destroy Plan') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform plan -destroy -input=false -var-file="${TF_VAR_FILE}" -out=tfplan
            '''
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform apply -input=false tfplan
            '''
          }
        }
      }
    }

    stage('Terraform Destroy') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        dir('terraform') {
          withCredentials([file(credentialsId: 'gcp-infra-admin', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              set -euo pipefail
              terraform apply -input=false tfplan
            '''
          }
        }
      }
    }

    stage('GKE Authentication') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          gcloud container clusters get-credentials "${CLUSTER_NAME}" \
            --region="${GCP_REGION}" \
            --project="${GCP_PROJECT_ID}"
          kubectl get nodes -o wide
        '''
      }
    }

    stage('Artifact Registry Authentication') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          gcloud auth configure-docker "${AR_HOST}" --quiet
        '''
      }
    }

    stage('Push Backend Image') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh 'docker push "${AR_REPO}/student-management-backend:${IMAGE_TAG}"'
      }
    }

    stage('Push Frontend Image') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh 'docker push "${AR_REPO}/student-management-frontend:${IMAGE_TAG}"'
      }
    }

    stage('Deploy Namespace') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh 'kubectl apply -f "${K8S_DIR}/namespace.yaml"'
      }
    }

    stage('Deploy PostgreSQL') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([string(credentialsId: 'student-management-postgres-password', variable: 'POSTGRES_PASSWORD')]) {
          sh '''
            set -euo pipefail
            kubectl -n student-management create secret generic student-management-postgres-secret \
              --from-literal=POSTGRES_DB=student_management \
              --from-literal=POSTGRES_USER=student_admin \
              --from-literal=POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
              --dry-run=client -o yaml | kubectl apply -f -
            kubectl apply -f "${K8S_DIR}/postgres-pvc.yaml"
            kubectl apply -f "${K8S_DIR}/postgres-statefulset.yaml"
            kubectl apply -f "${K8S_DIR}/postgres-service.yaml"
          '''
        }
      }
    }

    stage('Wait for PostgreSQL') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          kubectl -n student-management rollout status statefulset/student-management-postgres --timeout=300s
          kubectl wait --for=condition=Ready pod/student-management-postgres-0 -n student-management --timeout=300s
        '''
      }
    }

    stage('Deploy Backend') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        withCredentials([string(credentialsId: 'student-management-postgres-password', variable: 'POSTGRES_PASSWORD')]) {
          sh '''
            set -euo pipefail
            kubectl apply -f "${K8S_DIR}/configmap.yaml"
            kubectl -n student-management create secret generic student-management-backend-secret \
              --from-literal=DB_PASSWORD="${POSTGRES_PASSWORD}" \
              --dry-run=client -o yaml | kubectl apply -f -
            sed "s|:PLACEHOLDER|:${IMAGE_TAG}|g" "${K8S_DIR}/backend-deployment.yaml" | kubectl apply -f -
            kubectl apply -f "${K8S_DIR}/backend-service.yaml"
            kubectl -n student-management rollout status deployment/backend --timeout=300s
          '''
        }
      }
    }

    stage('Deploy Frontend') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          sed "s|:PLACEHOLDER|:${IMAGE_TAG}|g" "${K8S_DIR}/frontend-deployment.yaml" | kubectl apply -f -
          kubectl apply -f "${K8S_DIR}/frontend-service.yaml"
          kubectl -n student-management rollout status deployment/frontend --timeout=300s
        '''
      }
    }

    stage('Deploy Gateway') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          kubectl get gatewayclass gke-l7-regional-external-managed
          if ! kubectl get gatewayclass gke-l7-regional-external-managed >/dev/null 2>&1; then
            kubectl apply -f "${K8S_DIR}/gateway-class.yaml"
          fi
          kubectl apply -f "${K8S_DIR}/gateway.yaml"
          kubectl apply -f "${K8S_DIR}/healthcheck-policies.yaml"
        '''
      }
    }

    stage('Deploy HTTPRoute') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh 'kubectl apply -f "${K8S_DIR}/http-route.yaml"'
      }
    }

    stage('Verify Nodes') {
      when { expression { params.ACTION == 'apply' } }
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
      }
    }

    stage('Verify PostgreSQL') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          kubectl get statefulset -n student-management
          kubectl get pods -n student-management
          kubectl get pvc -n student-management
          kubectl get svc -n student-management
        '''
      }
    }

    stage('Verify Services') {
      when { expression { params.ACTION == 'apply' } }
      steps {
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
      }
    }

    stage('Verify Gateway') {
      when { expression { params.ACTION == 'apply' } }
      steps {
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
              exit 0
            fi
            echo "Waiting for Gateway address (${i}/60)..."
            sleep 10
          done
          echo "Gateway did not receive an address" >&2
          kubectl -n student-management describe gateway student-management-gateway
          exit 1
        '''
      }
    }

    stage('Verify Application') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          set -euo pipefail
          IP=$(cat "${WORKSPACE}/gateway-ip.txt")
          curl -fsS --retry 12 --retry-delay 10 --retry-all-errors "http://${IP}/" | head -c 200
          echo
          curl -fsS --retry 12 --retry-delay 10 --retry-all-errors "http://${IP}/api/students"
          echo
        '''
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed. Stop here. Do not continue to later phases, commit, or open a PR from a failed run.'
    }
  }
}
