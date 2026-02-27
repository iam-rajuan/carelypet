# CarelyPet Docker Deployment

## Files added

- Root `docker-compose.yml` for the full stack
- `deploy/nginx/default.conf` as the reverse proxy
- Production Docker image for `carelypet-dashboard`
- `.env.example` files for compose and backend secrets

## First-time setup

1. Copy `.env.example` to `.env` in the repository root.
2. Copy `carelypet-backend/.env.example` to `carelypet-backend/.env`.
3. Fill in every required backend secret before starting the stack.

## Start locally or on EC2

```bash
docker compose up -d --build
```

The services will be:

- `http://YOUR_HOST/` -> Next.js dashboard through Nginx
- `http://YOUR_HOST/api/v1` -> backend API through Nginx
- `http://YOUR_HOST/api-docs` -> Swagger UI from the backend

## EC2 notes

1. Install Docker Engine and Docker Compose plugin on the EC2 instance.
2. Open inbound security-group rules for `80` and, if you later terminate TLS on-instance, `443`.
3. Keep MongoDB private; this compose file does not expose port `27017` publicly.
4. Set `NEXT_PUBLIC_API_BASE_URL=/api/v1` unless you intentionally serve the API from another domain.
5. Rebuild after frontend env changes because `NEXT_PUBLIC_*` values are embedded at build time.

## EC2 helper scripts

Use the server bootstrap script once on Ubuntu EC2:

```bash
sudo bash deploy/ec2/setup-ec2.sh
```

Use the deployment script for normal releases:

```bash
bash deploy/ec2/deploy.sh
```

Use the HTTPS bootstrap script after your domain DNS points to the EC2 public IP:

```bash
bash deploy/ec2/enable-https.sh your-domain.com admin@your-domain.com
```

After HTTPS is enabled, deploy with:

```bash
bash deploy/ec2/deploy.sh --https
```

## GitHub Actions deploy

A workflow is included at `.github/workflows/deploy-ec2.yml`.

Set these repository secrets before using it:

- `EC2_HOST`
- `EC2_USERNAME`
- `EC2_SSH_PRIVATE_KEY`
- `EC2_APP_DIR`

The workflow assumes:

- the repo already exists on the EC2 instance
- deployments should run from the `main` branch
- HTTPS is enabled, so it executes `deploy/ec2/deploy.sh --https`

## Update deploy

```bash
docker compose down
docker compose up -d --build
```

## HTTPS flow

1. Create an A record for your domain pointing to the EC2 public IP.
2. Ensure the security group allows inbound `80` and `443`.
3. Run `deploy/ec2/enable-https.sh`.
4. From then on, use `deploy/ec2/deploy.sh --https`.

## Recommended production hardening

- Attach an Elastic IP or domain name to the EC2 instance.
- Add HTTPS via an ALB, Cloudflare Tunnel, or Nginx + Certbot.
- Store secrets outside git and inject real values through `.env` files or your CI/CD system.
