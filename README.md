UTC Student Services Portal — Infrastructure & CI/CD

Author: Matthew Oguguo

Terraform-managed AWS infrastructure and GitHub Actions CI/CD pipeline for the UTC Student Services Portal (utc-app), a 3-tier web application used by students and staff to check enrollment status, upload documents, request lab access, open support requests, and view course information.

This README is written as a step-by-step setup guide — follow it in order the first time you stand this project up, whether that's your own first deployment or someone cloning the repo later.

Table of contents
Architecture
Ticket → module map
Prerequisites
Step 1 — Set up remote state
Step 2 — Configure environment variables
Step 3 — Deploy the infrastructure
Step 4 — Set real secret values
Step 5 — Confirm the SNS email subscription
Step 6 — Set up GitHub Actions CI/CD
Step 7 — Deploy the application
Required inputs reference
Outputs reference
How the app reads secrets at runtime
Environment differences (dev vs. staging vs. prod)
End-to-end validation
Known follow-ups / not yet automated
Architecture
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
(private db     S3 (logs/backups/deploy artifacts)
 subnets)

GitHub Actions ──(OIDC, no stored keys)──▶ IAM role ──▶ S3 (app artifact) + SSM (deploy command) ──▶ EC2 instances
Network: VPC spanning a configurable number of AZs, with public, app, and db subnet tiers, an Internet Gateway, and configurable NAT Gateway count.
Edge: CloudFront distribution terminates HTTPS at the edge using an existing ACM certificate; ALB is the origin over HTTP internally. Route 53 alias record points the app domain at CloudFront.
Compute: Auto Scaling Group of EC2 instances (Amazon Linux 2023, always resolved via SSM parameter — no hardcoded AMI IDs), scaling on ALB request count per target. Instances mount EFS for file uploads, read secrets from Secrets Manager at boot via the instance role, and run the Flask app under gunicorn as a systemd service.
Database: RDS Postgres in private db subnets, reachable only from the app security group, automated backups enabled, RDS-managed master credentials (no plaintext passwords anywhere in this repo or state).
Storage: S3 bucket for logs/backups/deploy artifacts (versioned, encrypted, public access fully blocked, lifecycle rules to tier/expire objects) and EFS for app-server file uploads (encrypted, access-point scoped).
IAM: One instance role/profile for app servers with least-privilege policies scoped to the specific S3 prefixes, EFS access point, and secrets this app actually uses — plus SSM Session Manager for shell-less admin access (no SSH keys, no open port 22).
Secrets: Secrets Manager holds app-level secrets (JWT signing key, SMTP credentials, app encryption key) separately from the RDS-managed DB credentials. Only ARNs are ever passed through Terraform — real values are set out-of-band and never touch state or tfvars.
Observability: SNS topic with email subscriptions, CloudWatch alarms across the ASG, ALB, and RDS tiers, and a log group for app logs.
CI/CD: GitHub Actions authenticates to AWS via OIDC (no long-lived AWS keys in GitHub). On every push to main, it packages the Flask app, uploads it to S3, and triggers an SSM command that redeploys it on every app-tier instance.
Ticket → module map
Ticket	Module	What it covers
NET-001	modules/network	VPC, subnets, route tables, IGW, NAT gateways
SEC-001	modules/security	Security groups (ALB, app, db)
ING-001	modules/loadbalancer, modules/cdn	ACM lookup, ALB, HTTPS listener, CloudFront, Route 53
CMP-001	modules/compute	Launch template, Auto Scaling Group
DB-001	modules/database	RDS instance, subnet group, backups
STO-001	modules/storage	S3 bucket, EFS filesystem + access point
IAM-001	modules/iam	EC2 instance role, least-privilege policies
SEC-002	modules/secrets	Secrets Manager secret, IAM read access, runtime pattern
OBS-001	modules/observability	SNS topic, CloudWatch alarms, app log group
—	modules/cicd	GitHub OIDC provider/role, deploy permissions
IAC-001	this file + environments/	Structure, inputs/outputs reference, README
Prerequisites
Terraform >= 1.9.0
AWS provider ~> 5.0
An AWS account with credentials configured (aws configure or environment variables)
The Session Manager plugin installed locally, for shell-less access to instances
An existing Route 53 public hosted zone for your domain
An existing ACM certificate (in the same region as the ALB, and separately in us-east-1 for CloudFront if your ALB region differs) covering the domain, already ISSUED
A GitHub repository containing this code, with Actions enabled
Step 1 — Set up remote state

Each environment expects a backend.tf file (not committed — see .gitignore) copied from the matching backend.tf-example in that directory.

The S3 state bucket is created once, out-of-band (not by this Terraform config, to avoid a chicken-and-egg dependency):

bash
aws s3api create-bucket --bucket <TFSTATE_BUCKET_NAME> --region <AWS_REGION>
aws s3api put-bucket-versioning --bucket <TFSTATE_BUCKET_NAME> --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket <TFSTATE_BUCKET_NAME> --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket <TFSTATE_BUCKET_NAME> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

Then, per environment:

bash
cp environments/dev/backend.tf-example environments/dev/backend.tf
# edit environments/dev/backend.tf with your actual bucket name/region
cd environments/dev
terraform init

backend.tf uses native S3 state locking (use_lockfile = true, Terraform >= 1.10) — no DynamoDB table needed.

Step 2 — Configure environment variables

Copy the pattern in environments/dev/terraform.tfvars and fill in real values for your domain, GitHub repo, and preferences. See the Required inputs reference below for the full list.

Two GitHub-specific values need special attention. As of July 15, 2026, GitHub Actions OIDC tokens issued by repositories created (or renamed) after that date use an immutable subject claim format that embeds numeric owner/repo IDs instead of plain names, to prevent a security issue where a renamed or deleted repo's name could be reused by someone else. Find your repo's actual sub claim format one of two ways:

Preview it in GitHub: repo Settings → Actions → General → scroll to the OIDC section — GitHub shows the exact subject claim prefix your repo will emit.
Or read it from a failed AssumeRole attempt: if you configure the Terraform trust policy with plain names first and it fails, check CloudTrail for the AssumeRoleWithWebIdentity event — the userIdentity.principalId field shows the exact sub string GitHub actually sent.

Set both in terraform.tfvars:

hcl
github_org      = "your-org-or-username"
github_repo     = "your-repo-name"
github_org_id   = "your-org-or-username@123456"   # numeric owner ID
github_repo_id  = "your-repo-name@789012"          # numeric repo ID

create_oidc_provider = true   # false if your AWS account already has a GitHub OIDC provider (only one per account is allowed)
Step 3 — Deploy the infrastructure
bash
cd environments/dev
terraform plan
terraform apply

This creates every module above, including the CI/CD IAM role. Repeat for staging and prod with their respective directories once dev is verified.

Grab two outputs you'll need shortly:

bash
terraform output github_deploy_role_arn
terraform output storage_bucket_name
Step 4 — Set real secret values

terraform apply seeds the app secret with empty placeholder values for every key in app_secret_keys — Terraform never writes or tracks real secret values, by design. Set them once, manually, after every fresh apply:

bash
aws secretsmanager put-secret-value \
  --secret-id "$(terraform output -raw app_secret_arn)" \
  --secret-string '{
    "JWT_SIGNING_SECRET": "<generate a long random string>",
    "SMTP_USERNAME": "<your SMTP username>",
    "SMTP_PASSWORD": "<your SMTP password>",
    "APP_ENCRYPTION_KEY": "<generate a long random string>"
  }'

The RDS master password needs no action — it's fully managed and rotated by AWS automatically (manage_master_user_password = true).

Step 5 — Confirm the SNS email subscription

After apply, AWS emails every address in alert_email_addresses a subscription confirmation link. Nothing gets delivered until someone clicks it. Check the inbox and confirm before relying on alerts.

Step 6 — Set up GitHub Actions CI/CD

GitHub authenticates to AWS via OIDC — no long-lived AWS access keys are ever stored in GitHub.

In your GitHub repository: Settings → Secrets and variables → Actions → New repository secret.
Add two secrets, using the Terraform outputs from Step 3:
Secret name	Value
AWS_DEPLOY_ROLE_ARN	output of terraform output -raw github_deploy_role_arn
DEPLOY_BUCKET	output of terraform output -raw storage_bucket_name
Confirm .github/workflows/deploy.yml exists in the repo (it should already be committed) and triggers on push to main under the app/** path.
Push a commit touching anything under app/ to trigger the first run, and watch it in the Actions tab.

If the "Configure AWS credentials" step fails with Not authorized to perform sts:AssumeRoleWithWebIdentity, the most common causes, in order of likelihood:

The AWS_DEPLOY_ROLE_ARN secret doesn't match the current Terraform output (re-copy it — role ARNs change if the role is ever recreated).
github_org_id / github_repo_id in terraform.tfvars don't match your repo's actual immutable subject claim (see Step 2) — verify with CloudTrail as described there.
The workflow is missing permissions: id-token: write at the top level, or your org's Settings → Actions → General policy overrides it.
Step 7 — Deploy the application

Once Step 6's first workflow run succeeds, it will have:

Packaged app/ into a zip
Uploaded it to s3://<bucket>/deploy/latest.zip
Run /usr/local/bin/deploy-app.sh on every app-tier instance via SSM, which pulls the artifact, reinstalls dependencies, and restarts the utc-app systemd service

Verify it landed:

bash
curl -s https://<record_name>/          # expect "OK" (health check route)
curl -s https://<record_name>/signup    # expect the real signup page HTML

From here on, every push to main under app/** redeploys automatically — no manual steps.

Required inputs reference
Variable	Description	Example
aws_region	AWS region	"us-east-1"
app_name	App name, used in resource naming	"utc-app"
vpc_cidr	VPC CIDR block	"10.0.0.0/16"
az_count	Number of AZs to use	2
public_subnet_cidrs / app_subnet_cidrs / db_subnet_cidrs	CIDR list per tier	["10.0.0.0/24", ...]
nat_gateway_count	NAT gateways (1 = cost-saving, = az_count for full HA)	1
alb_ingress_cidrs / alb_ports	Public ALB access	["0.0.0.0/0"], [80, 443]
app_port	Port the app listens on	8080
db_port	Port the DB listens on	5432
zone_name	Route 53 hosted zone	"handart.site"
record_name	Full FQDN for the app	"utc-app-dev.handart.site"
certificate_domain	Domain to look up existing ACM cert	"*.handart.site"
instance_type / min_size / max_size / desired_capacity	ASG sizing	"t3.micro", 2, 6, 2
db_engine_major_version / db_instance_class	RDS engine config	"16", "db.t3.micro"
db_name / db_username	RDS initial DB + master username	"utcappdb", "app_admin"
db_multi_az / db_deletion_protection / db_skip_final_snapshot	RDS HA/safety flags	false / true for prod
s3_force_destroy	Allow bucket deletion with objects present (dev only)	true (dev), false (staging/prod)
app_secret_keys	Keys seeded (empty) into the app secret's JSON shape	["JWT_SIGNING_SECRET", "SMTP_USERNAME", "SMTP_PASSWORD", "APP_ENCRYPTION_KEY"]
secret_recovery_window_days	Days before a deleted secret purges	0 (dev), 7-30 (staging/prod)
alert_email_addresses	Emails subscribed to CloudWatch alarms	["ops@example.com"]
github_org / github_repo	Plain GitHub org/repo names (kept for reference/tags)	"matteceejay", "utc_app"
github_org_id / github_repo_id	Immutable name@id form used in the OIDC trust condition	"matteceejay@187773256", "utc_app@1359581022"
create_oidc_provider	Whether to create the GitHub OIDC provider (only one allowed per AWS account)	true / false
tags	Common tags applied everywhere	{ Project = "utc-app", Environment = "dev" }
Outputs reference
Output	Description
vpc_id	VPC ID
public_subnet_ids / app_subnet_ids / db_subnet_ids	Subnet ID lists per tier
alb_security_group_id / app_security_group_id / db_security_group_id	Security group IDs
alb_dns_name	ALB's own DNS name (internal origin, not user-facing)
target_group_arn	ALB target group ARN
asg_name	Auto Scaling Group name
db_master_secret_arn	Secrets Manager ARN for RDS-managed credentials
storage_bucket_name	S3 bucket name (also the CI/CD deploy artifact bucket)
efs_file_system_id / efs_access_point_id	EFS identifiers
app_role_arn / app_instance_profile_name	IAM role/profile for app instances
app_secret_arn	Secrets Manager ARN for app-level secrets
alerts_topic_arn	SNS topic ARN for CloudWatch alarms
github_deploy_role_arn	IAM role GitHub Actions assumes via OIDC — goes in the AWS_DEPLOY_ROLE_ARN GitHub secret
How the app reads secrets at runtime

The app never receives secret values through Terraform. Each instance boots with APP_SECRET_ARN, DB_SECRET_ARN, DB_HOST, DB_PORT, DB_NAME, and AWS_DEFAULT_REGION written to /etc/utc-app.env (via user data), loaded into the utc-app systemd service via EnvironmentFile=. At startup, the app calls secretsmanager:GetSecretValue directly using those ARNs — the instance role's attached policies (from IAM-001 and SEC-002) are the only thing authorizing that call. Real secret values are set once via the AWS CLI (Step 4) and are never re-applied by Terraform (lifecycle { ignore_changes = [secret_string] } on the placeholder version).

Environment differences (dev vs. staging vs. prod)
Setting	dev	staging	prod
nat_gateway_count	1	1–2	= az_count
db_multi_az	false	false	true
db_deletion_protection	false	false	true
db_skip_final_snapshot	true	true	false
s3_force_destroy	true	false	false
secret_recovery_window_days	0	7	30
record_name	utc-app-dev.<zone>	utc-app-staging.<zone>	utc-app.<zone>
End-to-end validation

These are the checks used to confirm the infrastructure and application actually work, not just that terraform apply succeeded. Run them in order — later steps assume earlier ones passed.

1. Public HTTPS endpoint resolves and serves a valid certificate
bash
dig +short <record_name>
curl -vI https://<record_name> 2>&1 | grep -E "subject:|HTTP/"

Expect: an IP address from dig, a certificate subject: matching your domain, and an HTTP response.

2. App servers are private and only reachable through the ALB
bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=<app-tag-name>" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,PrivateIpAddress]' --output table

aws ec2 describe-security-groups --group-ids <app_security_group_id> \
  --query 'SecurityGroups[0].IpPermissions'

Expect: PublicIpAddress is empty for every instance, and the only ingress rule references the ALB's security group ID, not 0.0.0.0/0.

3. RDS is private and only reachable from the app tier
bash
aws rds describe-db-instances --query \
  'DBInstances[?DBInstanceIdentifier==`<db_instance_id>`].[PubliclyAccessible,VpcSecurityGroups]'

aws ec2 describe-security-groups --group-ids <db_security_group_id> \
  --query 'SecurityGroups[0].IpPermissions'

Expect: PubliclyAccessible: false, and the only ingress rule references the app security group ID on the DB port.

4. Scaling and health checks are live
bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg_name> \
  --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity,HealthCheckType]'

aws elbv2 describe-target-health --target-group-arn <target_group_arn>

Expect: targets showing "State": "healthy".

5. The app itself responds
bash
curl -s https://<record_name>/
curl -s https://<record_name>/signup

Expect: OK from /, and real signup page HTML from /signup.

6. Secrets are readable only via the instance's IAM role
bash
aws ssm start-session --target <any-instance-id>

# inside the session:
cat /etc/utc-app.env
set -a; source /etc/utc-app.env; set +a
aws secretsmanager get-secret-value --secret-id "$APP_SECRET_ARN" --query SecretString --output text
aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --query SecretString --output text

Expect: both calls succeed with no AWS access keys configured on the instance. ⚠️ Real values print in plaintext — clear your terminal scrollback afterward.

7. CloudWatch alarms and SNS notifications exist
bash
aws cloudwatch describe-alarms --alarm-name-prefix <app_name>-<environment>
aws sns list-subscriptions-by-topic --topic-arn <alerts_topic_arn>

Expect: all alarms present, subscription shows a real SubscriptionArn.

8. Infrastructure is reproducible from code alone
bash
terraform plan

Expect: No changes. Your infrastructure matches the configuration.

9. CI/CD pipeline deploys successfully

Push a trivial change under app/, watch the Actions tab, and confirm all steps pass (checkout → install → package → assume role via OIDC → upload to S3 → SSM deploy). Then re-run check 5 to confirm the new code actually landed.

10. The full user flow works against real data

Sign up, log in, pick a career path, add courses to the cart, and check out. Then confirm the account and purchase actually exist in RDS (not a local SQLite fallback) via an SSM session, same pattern as check 6.

Known follow-ups / not yet automated
CloudWatch agent on instances — app log group exists (OBS-001) but nothing ships application-level logs to it yet; gunicorn/systemd logs are only visible via journalctl over SSM today.
ALB direct-access hardening — the ALB security group still accepts 0.0.0.0/0, allowing bypass of CloudFront; restricting to the CloudFront managed prefix list was proposed but not yet applied.
RDS secret rotation — not yet enabled; needs a rotation Lambda if required.
Real payment integration — checkout currently records a mock payment only; no real payment processor is integrated.
Staging/prod CI/CD — the GitHub Actions workflow currently deploys to dev only; staging/prod would need their own workflow (or a branch/environment-gated version of the same one) plus separate AWS_DEPLOY_ROLE_ARN / DEPLOY_BUCKET secrets per environment.