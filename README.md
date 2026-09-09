# utc_app# UTC Student Services Portal — Infrastructure

Terraform-managed AWS infrastructure for the UTC Student Services Portal
(`utc-app`), a 3-tier web application used by students and staff to check
enrollment status, upload documents, request lab access, open support
requests, and view course information.

## Architecture

```
Internet
   │
   ▼
CloudFront (HTTPS, edge caching)
   │
   ▼
ALB (public subnets, HTTPS listener, ACM cert)
   │
   ▼
Auto Scaling Group — EC2 app servers (private app subnets)
   │              │
   ▼              ▼
RDS Postgres    EFS (uploads)
(private db     S3 (logs/backups)
 subnets)
```

- **Network**: VPC spanning a configurable number of AZs, with public,
  app, and db subnet tiers, an Internet Gateway, and configurable NAT
  Gateway count.
- **Edge**: CloudFront distribution terminates HTTPS at the edge using an
  existing ACM certificate; ALB is the origin over HTTP internally.
  Route 53 alias record points the app domain at CloudFront.
- **Compute**: Auto Scaling Group of EC2 instances (Amazon Linux 2023,
  always resolved via SSM parameter — no hardcoded AMI IDs), scaling on
  ALB request count per target. Instances mount EFS for file uploads and
  read secrets from Secrets Manager at boot via the instance role.
- **Database**: RDS Postgres in private db subnets, reachable only from
  the app security group, automated backups enabled, RDS-managed master
  credentials (no plaintext passwords anywhere in this repo or state).
- **Storage**: S3 bucket for logs/backups (versioned, encrypted, public
  access fully blocked, lifecycle rules to tier/expire objects) and EFS
  for app-server file uploads (encrypted, access-point scoped).
- **IAM**: One instance role/profile for app servers with least-privilege
  policies scoped to the specific S3 prefixes, EFS access point, and
  secrets this app actually uses — plus SSM Session Manager for shellless
  admin access (no SSH keys, no open port 22).
- **Secrets**: Secrets Manager holds app-level secrets (JWT signing key,
  SMTP credentials, app encryption key) separately from the RDS-managed
  DB credentials. Only ARNs are ever passed through Terraform — real
  values are set out-of-band and never touch state or tfvars.
- **Observability**: SNS topic with email subscriptions, CloudWatch
  alarms across the ASG, ALB, and RDS tiers, and a log group for app
  logs.

## Ticket → module map

| Ticket   | Module               | What it covers                                  |
|----------|-----------------------|--------------------------------------------------|
| NET-001  | `modules/network`      | VPC, subnets, route tables, IGW, NAT gateways    |
| SEC-001  | `modules/security`     | Security groups (ALB, app, db)                   |
| ING-001  | `modules/loadbalancer`, `modules/cdn` | ACM lookup, ALB, HTTPS listener, CloudFront, Route 53 |
| CMP-001  | `modules/compute`      | Launch template, Auto Scaling Group              |
| DB-001   | `modules/database`     | RDS instance, subnet group, backups              |
| STO-001  | `modules/storage`      | S3 bucket, EFS filesystem + access point         |
| IAM-001  | `modules/iam`          | EC2 instance role, least-privilege policies      |
| SEC-002  | `modules/secrets`      | Secrets Manager secret, IAM read access, runtime pattern |
| OBS-001  | `modules/observability`| SNS topic, CloudWatch alarms, app log group      |
| IAC-001  | this file + `environments/` | Structure, inputs/outputs reference, README |

## Prerequisites

- Terraform >= 1.9.0
- AWS provider ~> 5.0
- An AWS account with credentials configured (`aws configure` or
  environment variables)
- An existing Route 53 public hosted zone for your domain
- An existing ACM certificate (in the same region as the ALB, and
  separately in `us-east-1` for CloudFront if your ALB region differs)
  covering the domain, already `ISSUED`

## Usage

Each environment is a standalone root module under `environments/`.

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

Repeat for `staging` and `prod` with their respective directories. State
is isolated per environment — configure a remote backend (S3 + DynamoDB
lock table, or Terraform Cloud) per environment before using this in a
team setting; the `backend` block is currently commented out in each
`main.tf` as a placeholder.

## Required inputs (per environment `terraform.tfvars`)

| Variable | Description | Example |
|---|---|---|
| `aws_region` | AWS region | `"us-east-1"` |
| `app_name` | App name, used in resource naming | `"utc-app"` |
| `vpc_cidr` | VPC CIDR block | `"10.0.0.0/16"` |
| `az_count` | Number of AZs to use | `2` |
| `public_subnet_cidrs` / `app_subnet_cidrs` / `db_subnet_cidrs` | CIDR list per tier | `["10.0.0.0/24", ...]` |
| `nat_gateway_count` | NAT gateways (1 = cost-saving, = az_count for full HA) | `1` |
| `alb_ingress_cidrs` / `alb_ports` | Public ALB access | `["0.0.0.0/0"]`, `[80, 443]` |
| `app_port` | Port the app listens on | `8080` |
| `db_port` | Port the DB listens on | `5432` |
| `zone_name` | Route 53 hosted zone | `"handart.site"` |
| `record_name` | Full FQDN for the app | `"dev.utc-app.handart.site"` |
| `certificate_domain` | Domain to look up existing ACM cert | `"*.handart.site"` |
| `instance_type` / `min_size` / `max_size` / `desired_capacity` | ASG sizing | `"t3.micro"`, `2`, `6`, `2` |
| `db_engine` / `db_engine_version` / `db_instance_class` | RDS engine config | `"postgres"`, `"16.4"`, `"db.t3.micro"` |
| `db_name` / `db_username` | RDS initial DB + master username | `"utcappdb"`, `"app_admin"` |
| `db_multi_az` / `db_deletion_protection` / `db_skip_final_snapshot` | RDS HA/safety flags | `false` / `true` for prod |
| `s3_force_destroy` | Allow bucket deletion with objects present (dev only) | `true` (dev), `false` (staging/prod) |
| `app_secret_keys` | Keys seeded into the app secret's JSON shape | `["JWT_SIGNING_SECRET", "SMTP_USERNAME", "SMTP_PASSWORD", "APP_ENCRYPTION_KEY"]` |
| `secret_recovery_window_days` | Days before a deleted secret purges | `0` (dev), `7-30` (staging/prod) |
| `alert_email_addresses` | Emails subscribed to CloudWatch alarms | `["ops@example.com"]` |
| `tags` | Common tags applied everywhere | `{ Project = "utc-app", Environment = "dev" }` |

## Outputs (per environment)

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` / `app_subnet_ids` / `db_subnet_ids` | Subnet ID lists per tier |
| `alb_security_group_id` / `app_security_group_id` / `db_security_group_id` | Security group IDs |
| `alb_dns_name` | ALB's own DNS name (internal origin, not user-facing) |
| `target_group_arn` | ALB target group ARN |
| `cdn_domain_name` | CloudFront distribution domain |
| `app_url` | Public HTTPS URL for the app (`https://<record_name>`) |
| `asg_name` | Auto Scaling Group name |
| `db_endpoint` | RDS connection endpoint (host:port) |
| `db_master_secret_arn` | Secrets Manager ARN for RDS-managed credentials |
| `storage_bucket_name` | S3 bucket name |
| `efs_file_system_id` / `efs_access_point_id` | EFS identifiers |
| `app_role_arn` / `app_instance_profile_name` | IAM role/profile for app instances |
| `app_secret_arn` | Secrets Manager ARN for app-level secrets |
| `alerts_topic_arn` | SNS topic ARN for CloudWatch alarms |

## Secrets — how the app reads them

The app never receives secret *values* through Terraform. Each instance
boots with `APP_SECRET_ARN` and `DB_SECRET_ARN` in `/etc/environment`
(set via user data) and an IAM role authorized to read exactly those two
secrets (from IAM-001 and SEC-002). At runtime, the app calls
`secretsmanager:GetSecretValue` directly using those ARNs. Real secret
values are set once via the AWS console or CLI after `apply` and are
never re-applied by Terraform (`lifecycle { ignore_changes = [secret_string] }`
on the placeholder version).

## Environment differences (dev vs. staging vs. prod)

| Setting | dev | staging | prod |
|---|---|---|---|
| `nat_gateway_count` | 1 | 1–2 | = `az_count` |
| `db_multi_az` | `false` | `false` | `true` |
| `db_deletion_protection` | `false` | `false` | `true` |
| `db_skip_final_snapshot` | `true` | `true` | `false` |
| `s3_force_destroy` | `true` | `false` | `false` |
| `secret_recovery_window_days` | `0` | `7` | `30` |
| `record_name` | `dev.utc-app.<zone>` | `staging.utc-app.<zone>` | `utc-app.<zone>` |

## Known follow-ups / not yet automated

- **CloudWatch agent on instances** — app log group exists (OBS-001) but
  nothing ships logs to it yet; needs agent install + config in compute
  user data once the app's actual log location is known.
- **Real app bootstrap** — `user_data` currently mounts EFS and exports
  secret ARNs, but the actual application install/start step is a
  placeholder pending a deploy method (bake into AMI, pull from S3/ECR,
  CodeDeploy, etc.).
- **ALB direct-access hardening** — the ALB security group still accepts
  `0.0.0.0/0`, allowing bypass of CloudFront; restricting to the
  CloudFront managed prefix list was proposed but not yet applied.
- **RDS secret rotation** — not yet enabled; needs a rotation Lambda if
  required.
- **Remote state backend** — `backend "s3"` blocks are commented
  placeholders; need real bucket/lock table per environment before
  team use.




  ## Remote state setup

Each environment expects a `backend.tf` file (not committed — see `.gitignore`)
copied from the matching `backend.tf-example` in that directory, with the
bucket name and region filled in:

​```bash
cp environments/dev/backend.tf-example environments/dev/backend.tf
# edit environments/dev/backend.tf with your actual bucket name/region
cd environments/dev
terraform init
​```

The S3 bucket itself is created once, out-of-band (not by this Terraform
config, to avoid a chicken-and-egg dependency):

​```bash
aws s3api create-bucket --bucket <TFSTATE_BUCKET_NAME> --region <AWS_REGION>
aws s3api put-bucket-versioning --bucket <TFSTATE_BUCKET_NAME> --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket <TFSTATE_BUCKET_NAME> --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket <TFSTATE_BUCKET_NAME> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
​```







## End-to-end validation

These are the checks used to confirm the infrastructure actually works,
not just that `terraform apply` succeeded. Run them in order — later
steps assume earlier ones passed.

### 1. Public HTTPS endpoint resolves and serves a valid certificate

```bash
dig +short <record_name>              # e.g. utc-app-dev.handart.site
curl -vI https://<record_name> 2>&1 | grep -E "subject:|HTTP/"
```
**Expect:** an IP address from `dig`, a certificate `subject:` matching
your domain, and an HTTP response — not a connection error or timeout.

### 2. App servers are private and only reachable through the ALB

```bash
# No public IPs on app instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=<app-tag-name>" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,PrivateIpAddress]' --output table

# App security group only allows the ALB's security group in - no open CIDRs
aws ec2 describe-security-groups --group-ids <app_security_group_id> \
  --query 'SecurityGroups[0].IpPermissions'
```
**Expect:** `PublicIpAddress` is empty for every instance, and the only
ingress rule references the ALB's security group ID, not `0.0.0.0/0`.

### 3. RDS is private and only reachable from the app tier

```bash
aws rds describe-db-instances --query \
  'DBInstances[?DBInstanceIdentifier==`<db_instance_id>`].[PubliclyAccessible,VpcSecurityGroups]'

aws ec2 describe-security-groups --group-ids <db_security_group_id> \
  --query 'SecurityGroups[0].IpPermissions'
```
**Expect:** `PubliclyAccessible: false`, and the only ingress rule
references the app security group ID on the DB port — no CIDR ranges.

### 4. Scaling and health checks are live, not just configured

```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg_name> \
  --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity,HealthCheckType]'

aws autoscaling describe-policies --auto-scaling-group-name <asg_name>

aws elbv2 describe-target-health --target-group-arn <target_group_arn>
```
**Expect:** a target-tracking scaling policy present, and targets
showing `"State": "healthy"` — not just a config that looks right on
paper.

### 5. The app itself responds

```bash
curl -s https://<record_name>
```
**Expect:** a real response from the application (not a redirect loop,
not a 503). A `301`/`302` pointing back at the same host on a different
port usually means an ALB listener is misconfigured; a `503` usually
means no healthy targets yet.

### 6. Secrets are readable only via the instance's IAM role — never hardcoded

```bash
aws ssm start-session --target <any-instance-id>

# once connected, inside the session:
cat /etc/environment                  # confirms the secret ARNs were injected at boot
source /etc/environment
aws secretsmanager get-secret-value --secret-id "$APP_SECRET_ARN" --query SecretString --output text
aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --query SecretString --output text
```
**Expect:** both calls succeed with no AWS access keys configured on the
instance — only the attached instance role authorizes them. Requires
the Session Manager plugin installed locally
([AWS docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)).

⚠️ Real secret values will print in plaintext to your terminal — avoid
pasting this output anywhere, and clear your terminal scrollback after.

### 7. CloudWatch alarms and SNS notifications exist and are wired up

```bash
aws cloudwatch describe-alarms --alarm-name-prefix <app_name>-<environment>
aws sns list-subscriptions-by-topic --topic-arn <alerts_topic_arn>
```
**Expect:** all alarms present, and the email subscription shows a real
`SubscriptionArn` — not `PendingConfirmation` (confirm by clicking the
link in the subscription email).

### 8. Infrastructure is reproducible from code alone

```bash
terraform plan
```
**Expect:** `No changes. Your infrastructure matches the configuration.`
This confirms state, code, and real infrastructure all agree — proving
the environment isn't held together by manual console changes.