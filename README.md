# Provision a Google Cloud GCP GKE Autopilot Cluster with Kong Real IPs using external secrets

Demonstration of using kubernetes external secrets with Google Secret Manager. Based on the external-secrets.io [documentation](https://external-secrets.io/v0.8.3/provider/google-secrets-manager/)

## Not for production use.


### Deployment

Check that all the APIs are enabled
```
$ gcloud services list --enabled
NAME                                 TITLE
appengine.googleapis.com             App Engine Admin API
appenginereporting.googleapis.com    App Engine
autoscaling.googleapis.com           Cloud Autoscaling API
bigquerystorage.googleapis.com       BigQuery Storage API
certificatemanager.googleapis.com    Certificate Manager API
cloudapis.googleapis.com             Google Cloud APIs
cloudbuild.googleapis.com            Cloud Build API
clouddebugger.googleapis.com         Cloud Debugger API
cloudresourcemanager.googleapis.com  Cloud Resource Manager API
cloudscheduler.googleapis.com        Cloud Scheduler API
cloudtrace.googleapis.com            Cloud Trace API
compute.googleapis.com               Compute Engine API
container.googleapis.com             Kubernetes Engine API
containerregistry.googleapis.com     Container Registry API
datastore.googleapis.com             Cloud Datastore API
deploymentmanager.googleapis.com     Cloud Deployment Manager V2 API
iam.googleapis.com                   Identity and Access Management (IAM) API
iamcredentials.googleapis.com        IAM Service Account Credentials API
logging.googleapis.com               Cloud Logging API
monitoring.googleapis.com            Cloud Monitoring API
oslogin.googleapis.com               Cloud OS Login API
secretmanager.googleapis.com         Secret Manager API
servicemanagement.googleapis.com     Service Management API
serviceusage.googleapis.com          Service Usage API

  $ gcloud services enable autoscaling.googleapis.com
  $ gcloud services enable cloudapis.googleapis.com
  $ gcloud services enable compute.googleapis.com
  $ gcloud services enable iam.googleapis.com
  $ gcloud services enable iamcredentials.googleapis.com
  $ gcloud services enable logging.googleapis.com
  $ gcloud services enable monitoring.googleapis.com
  $ gcloud services enable secretmanager.googleapis.com
  $ gcloud services enable servicemanagement.googleapis.com
  $ gcloud services enable serviceusage.googleapis.com
  $ gcloud services enable cloudresourcemanager.googleapis.com
  $ gcloud services enable container.googleapis.com
```

Create a terraform.tfvars file containing something similar to the following:

    credentials_file  = "wibbly-flibble-stuff-morestuff.json"
    project           = "wibble-flibble-numbers"
    region            = "europe-west2"

Create the service account keys which will be used for terraform wibbly-flibble-stuff-morestuff.json using:

    $ gcloud iam service-accounts keys create wibbly-flibble-stuff-morestuff.json \
    --iam-account=SA_NAME@PROJECT_ID.iam.gserviceaccount.com 


Run the standard terraform deployment:
   ```
   $ terraform init
   $ terraform plan
   $ terraform apply
   ```

### Create the TLS certificate in GCP Secret Manager secret so it can be imported via k8s for use with Kong

Create an example.txt file which looks like the following
```
$ openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=Lancashire/L=Ramsbottom/O=Widgets Inc/OU=Engineering/CN=mysuperdupersite.com"
$ cat cert.pem | base64 -w 0 >> example.txt
$ echo "\n" >> example.txt
$ cat key.pem | base64 -w 0 >> example.txt
```
Edit example.txt so that it looks similar to the following:
```
{
"tls.crt":"<base64 encoded cert and ca bundle string>",
"tls.key":"<base64 encoded key string>"
}
```
Now import the secret into kong-proxy-tls secret in secret manager
```
 $  gcloud secrets create kong-proxy-tls
 Created secret [kong-proxy-tls].
 $  gcloud secrets versions add kong-proxy-tls --data-file="example.txt"
 Created version [1] of the secret [kong-proxy-tls].
 $  gcloud secrets versions list kong-proxy-tls
 NAME  STATE    CREATED              DESTROYED
 1     enabled  2023-06-25T08:51:45  -
 $  gcloud secrets versions describe --secret kong-proxy-tls 1
 clientSpecifiedPayloadChecksum: true
 createTime: '2023-06-25T08:51:45.031774Z'
 etag: '"15fef057f8065e"'
 name: projects/123456789/secrets/kong-proxy-tls/versions/1
 replicationStatus:
   automatic: {}
 state: ENABLED

```

#### Retrieve k8s cluster credentials from GCP
```
$ gcloud auth login
$ export KUBECONFIG=~/.kube/config
$ export KUBE_CONFIG_PATH=$KUBECONFIG
$ gcloud container clusters get-credentials <project_name>-gke --region=europe-west2
```

### Prove this is working
```
$ kubectl get svc -n kong
NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
kong-kong-proxy                LoadBalancer   10.192.112.138   34.142.99.225   80:30470/TCP,443:30551/TCP   7m52s
kong-kong-validation-webhook   ClusterIP      10.192.96.19     <none>          443/TCP                      7m52s

$ curl -I -v https://34.142.99.225 -k
*   Trying 34.142.99.225:443...
* Connected to 34.142.99.225 (34.142.99.225) port 443 (#0)
* ALPN: offers h2,http/1.1.
.....
*  subject: C=XX; ST=Lancashire; L=Ramsbottom; O=Widgets Inc; OU=Engineering; CN=mysuperdupersite.com
*  start date: Jun 25 10:29:04 2023 GMT
*  expire date: Jun 22 10:29:04 2033 GMT
*  issuer: C=XX; ST=Lancashire; L=Ramsbottom; O=Widgets Inc; OU=Engineering; CN=mysuperdupersite.com
*  SSL certificate verify result: self-signed certificate (18), continuing anyway.
* using HTTP/2
* h2h3 [:method: HEAD]
* h2h3 [:path: /]
* h2h3 [:scheme: https]
* h2h3 [:authority: 34.142.99.225]
* h2h3 [user-agent: curl/7.88.1]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x56033ae7fc70)
> HEAD / HTTP/2
> Host: 34.142.99.225
> user-agent: curl/7.88.1
> accept: */*
> 
$ kubectl get ingressclass
NAME   CONTROLLER                            PARAMETERS   AGE
kong   ingress-controllers.konghq.com/kong   <none>       6m24s
```

### Check Real IP
```
$ kubectl logs pod/kong-kong-6cf4b6489f-42zxr -n kong -c proxy | egrep curl
1.2.3.4 - - [25/Jun/2023:10:44:35 +0000] "HEAD / HTTP/2.0" 404 0 "-" "curl/7.88.1"
```
