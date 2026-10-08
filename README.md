# Cloud CI/CD Deployment Pipeline

A demonstration-ready AWS DevOps project that provisions infrastructure with Terraform and deploys a containerized Flask + PostgreSQL application through GitHub Actions.

## What this demonstrates

- Terraform provisions the AWS VPC, EC2, ECR, RDS PostgreSQL, Elastic IP, IAM role and security groups.
- Flask runs as a Docker container on EC2.
- GitHub Actions performs CI: dependency installation, Python syntax validation and Docker build.
- GitHub Actions performs CD: Terraform plan/apply, Docker build and ECR push.
- Images are tagged with the immutable Git commit SHA.
- AWS Systems Manager performs remote deployment without an SSH key in GitHub Actions.
- The deployment script keeps the previous container, performs an application health check, and automatically restores it if the new release fails.
- Caddy terminates HTTPS and automatically manages/renews Let's Encrypt certificates.
- SSH port 22 is restricted to `ADMIN_CIDR` only.
- PostgreSQL is not publicly accessible; its security group permits port 5432 only from the EC2 security group.

## Architecture

```text
Developer -> git push -> GitHub Actions
                         |-- CI: test + Docker build
                         |-- Terraform: AWS infrastructure
                         |-- Docker build -> ECR:<commit-sha>
                         '-- SSM -> EC2
                                  |-- previous container backup
                                  |-- new container
                                  |-- /healthz check
                                  '-- rollback on failure
                                      |
                                      +-- Caddy :80/:443
                                      |       '-- HTTPS / automatic renewal
                                      |
                                      '-- Flask :5000 -> RDS PostgreSQL
```

## Required GitHub secrets

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DB_USERNAME
DB_PASSWORD
ADMIN_CIDR
DOMAIN_NAME
```

`ADMIN_CIDR` should be your public IP with `/32`, for example `203.0.113.10/32`.

`DOMAIN_NAME` must be a DNS name you control, for example `app.example.com`.

## DNS / HTTPS setup

1. Run the first deployment.
2. Get the Terraform `elastic_ip` output.
3. Create an A record for `DOMAIN_NAME` pointing to that Elastic IP.
4. Run the workflow again after DNS resolves.
5. Caddy will obtain the certificate automatically from Let's Encrypt and renew it automatically.

For a real HTTPS certificate, the domain must resolve publicly to the EC2 Elastic IP and ports 80/443 must be reachable.

## Demonstrating CI/CD

Make a visible change to `templates/hello.html`, then:

```bash
git add .
git commit -m "Update greeting UI"
git push origin main
```

GitHub Actions will show:

```text
CI
  -> Python check
  -> Docker build

CD
  -> Terraform init/validate/plan/apply
  -> ECR login
  -> Docker build
  -> Push <git-sha>
  -> SSM deployment
  -> /healthz check
  -> HTTPS smoke test
```

## Demonstrating rollback

Temporarily introduce a startup failure or invalid application configuration, push it, and show that the deployment health check fails. The EC2 script removes the failed container, restores `cloud-cicd-previous`, starts it, and exits the workflow with failure. The previous version remains live.

Restore the application and push a valid commit to deploy again.

## Local run

```bash
python -m venv .venv
.venv\\Scripts\\activate
pip install -r requirements.txt
```

Set `DB_HOST`, `DB_NAME`, `DB_USER` and `DB_PASS`, then:

```bash
python app.py
```

## Cleanup

After the AWS demonstration:

```bash
cd terraform
terraform destroy
```
