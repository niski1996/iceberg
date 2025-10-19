#!/bin/bash
echo "downloading helm"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

helm repo add minio https://charts.min.io/
helm repo update
helm pull minio/minio --untar
helm install --namespace iceberg --set rootUser=rootuser,rootPassword=rootpass123 --generate-name minio/minio

#!/bin/bash

cat <<EOF > ./minio/values.yaml
## Helm values for MinIO

nameOverride: ""
fullnameOverride: ""
clusterDomain: cluster.local

image:
  repository: quay.io/minio/minio
  tag: RELEASE.2024-12-18T13-15-44Z
  pullPolicy: IfNotPresent

mcImage:
  repository: quay.io/minio/mc
  tag: RELEASE.2024-11-21T17-21-54Z
  pullPolicy: IfNotPresent

mode: standalone
replicas: 1

additionalLabels: {}
additionalAnnotations: {}
ignoreChartChecksums: false
extraArgs: []
extraVolumes: []
extraVolumeMounts: []
extraContainers: []

minioAPIPort: "9000"
minioConsolePort: "9001"

deploymentUpdate:
  type: RollingUpdate
  maxUnavailable: 0
  maxSurge: 100%

statefulSetUpdate:
  updateStrategy: RollingUpdate

priorityClassName: ""
runtimeClassName: ""

rootUser: iceberguser
rootPassword: icebergpass
existingSecret: ""

certsPath: "/etc/minio/certs/"
configPathmc: "/etc/minio/mc/"

mountPath: "/export"
bucketRoot: ""

drivesPerNode: 1
pools: 1

tls:
  enabled: false
  certSecret: ""
  publicCrt: public.crt
  privateKey: private.key
trustedCertsSecret: ""

persistence:
  enabled: true
  annotations: {}
  existingClaim: ""
  storageClass: ""
  volumeName: ""
  accessMode: ReadWriteOnce
  size: 5Gi
  subPath: ""

service:
  type: ClusterIP
  clusterIP: ~
  port: "9000"
  nodePort: 32000
  loadBalancerIP: ~
  externalIPs: []
  annotations: {}
  loadBalancerSourceRanges: []
  externalTrafficPolicy: Cluster

ingress:
  enabled: false
  ingressClassName: ~
  labels: {}
  annotations: {}
  path: /
  hosts:
    - minio-example.local
  tls: []

consoleService:
  type: ClusterIP
  clusterIP: ~
  port: "9001"
  nodePort: 32001
  loadBalancerIP: ~
  externalIPs: []
  annotations: {}
  loadBalancerSourceRanges: []
  externalTrafficPolicy: Cluster

consoleIngress:
  enabled: false
  ingressClassName: ~
  labels: {}
  annotations: {}
  path: /
  hosts:
    - console.minio-example.local
  tls: []

nodeSelector: {}
tolerations: []
affinity: {}
topologySpreadConstraints: []

securityContext:
  enabled: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  fsGroupChangePolicy: "OnRootMismatch"

containerSecurityContext:
  readOnlyRootFilesystem: false

podAnnotations: {}
podLabels: {}

resources:
  requests:
    memory: 16Gi

policies: []

users:
  - accessKey: iceberguser
    secretKey: icebergpass
    policy: consoleAdmin

makePolicyJob:
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
  resources:
    requests:
      memory: 128Mi
  exitCommand: ""

makeUserJob:
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
  resources:
    requests:
      memory: 128Mi
  exitCommand: ""

svcaccts: []

makeServiceAccountJob:
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
  resources:
    requests:
      memory: 128Mi
  exitCommand: ""

buckets:
  - name: iceberg-data
    policy: none
    purge: false
    versioning: false
    objectlocking: false

makeBucketJob:
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
  resources:
    requests:
      memory: 128Mi
  exitCommand: ""

customCommands: []
customCommandJob:
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
  resources:
    requests:
      memory: 128Mi
  extraVolumes: []
  extraVolumeMounts: []
  exitCommand: ""

postJob:
  podAnnotations: {}
  annotations: {}
  securityContext:
    enabled: false
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  nodeSelector: {}
  tolerations: []
  affinity: {}

environment: {}
extraSecret: ~

oidc:
  enabled: false
  configUrl: "https://identity-provider-url/.well-known/openid-configuration"
  clientId: "minio"
  clientSecret: ""
  existingClientSecretName: ""
  existingClientIdKey: ""
  existingClientSecretKey: ""
  claimName: "policy"
  scopes: "openid,profile,email"
  redirectUri: "https://console-endpoint-url/oauth_callback"
  claimPrefix: ""
  comment: ""
  displayName: ""

networkPolicy:
  enabled: false
  flavor: kubernetes
  allowExternal: true
  egressEntities:
   - kube-apiserver

podDisruptionBudget:
  enabled: false
  maxUnavailable: 1

serviceAccount:
  create: true
  name: "minio-sa"

metrics:
  serviceMonitor:
    enabled: false
    includeNode: false
    public: true
    additionalLabels: {}
    annotations: {}
    relabelConfigs: {}
    relabelConfigsCluster: {}
    namespace: ~
    interval: ~
    scrapeTimeout: ~

etcd:
  endpoints: []
  pathPrefix: ""
  corednsPathPrefix: ""
  clientCert: ""
  clientCertKey: ""

EOF

cd ./minio
helm template minio ./ \
  --namespace iceberg \
  --values values.yaml \
  > minio-deploy.yaml

kubectl get namespaces
kubectl apply -f minio/minio-deploy.yaml