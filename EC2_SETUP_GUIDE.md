# EC2 Deployment Guide

This guide starts after:

- the EC2 instance is created
- the Elastic IP is attached to the instance
- you have the `.pem` key file on your computer
- you will use WSL on your local machine

## 1. Prepare your local WSL terminal

Move your EC2 key into WSL if it is still only on Windows.

Example:

```bash
mkdir -p ~/.ssh
cp /mnt/c/Users/YOUR_WINDOWS_USER/Downloads/your-key.pem ~/.ssh/carelypet-ec2.pem
chmod 400 ~/.ssh/carelypet-ec2.pem
```

Replace:

- `YOUR_WINDOWS_USER` with your Windows username
- `your-key.pem` with your actual EC2 key filename

## 2. Connect to the EC2 instance

Find your Elastic IP and connect:

```bash
ssh -i ~/.ssh/carelypet-ec2.pem ubuntu@YOUR_ELASTIC_IP
```

If your AMI is not Ubuntu, the username may be different:

- Ubuntu AMI: `ubuntu`
- Amazon Linux AMI: `ec2-user`

## 3. Update the server and install git

Run on the EC2 instance:

```bash
sudo apt update && sudo apt install -y git
```

## 4. Clone the project onto EC2

Choose a directory and clone the repo:

```bash
cd ~
git clone YOUR_REPOSITORY_URL carelypet
cd carelypet
```

If the repo is private, use either:

- an SSH git URL with a key already configured on the server
- a GitHub personal access token over HTTPS

## 5. Install Docker on EC2

Run:

```bash
sudo bash deploy/ec2/setup-ec2.sh
```

After that, reconnect to the server so your user gets Docker group access:

```bash
exit
ssh -i ~/.ssh/carelypet-ec2.pem ubuntu@YOUR_ELASTIC_IP
cd ~/carelypet
```

## 6. Create the required environment files

Create the root env file:

```bash
cp .env.example .env
```

Create the backend env file:

```bash
cp carelypet-backend/.env.example carelypet-backend/.env
```

## 7. Edit the root `.env`

Open it:

```bash
nano .env
```

Set at least:

```env
PROXY_PORT=80
NEXT_PUBLIC_API_BASE_URL=/api/v1
DOMAIN_NAME=
LETSENCRYPT_EMAIL=
HTTPS_PORT=443
```

For the first HTTP-only deploy:

- keep `NEXT_PUBLIC_API_BASE_URL=/api/v1`
- leave `DOMAIN_NAME` empty until DNS is ready
- leave `LETSENCRYPT_EMAIL` empty until HTTPS setup

Save in `nano`:

- `Ctrl+O`, Enter
- `Ctrl+X`

## 8. Edit `carelypet-backend/.env`

Open it:

```bash
nano carelypet-backend/.env
```

Fill all required values. Minimum important items:

```env
NODE_ENV=production
BASE_URL=/api/v1
PORT=5191
MONGO_URI=mongodb://mongo:27017/carelypet_db
JWT_SECRET=put-a-long-random-secret-here
JWT_EXPIRES_IN=7d
ACCESS_TOKEN_EXPIRES_IN=480m
REFRESH_TOKEN_EXPIRES_IN=7d
SETUP_TOKEN_EXPIRES_IN=30m
ADMIN_PASSWORD=put-a-strong-admin-password-here
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_BUCKET_NAME=your-s3-bucket
AWS_REGION=your-region
RESEND_API_KEY=your-resend-key
RESEND_FROM=your-verified-email-or-domain
STRIPE_SECRET_KEY=your-stripe-secret-if-used
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret-if-used
STRIPE_CURRENCY=usd
ORG_NAME=Carely Pets
FIREBASE_WEB_API_KEY=your-firebase-web-api-key-if-used
```

Notes:

- do not use placeholder values in production
- `MONGO_URI` should stay `mongodb://mongo:27017/carelypet_db` for this Docker setup
- the frontend reads `NEXT_PUBLIC_API_BASE_URL` at build time, so if you change it later you must rebuild

## 9. Check the EC2 security group

In AWS, make sure inbound rules allow:

- `22` for SSH from your IP
- `80` for HTTP
- `443` for HTTPS

Do not open `27017` publicly.

## 10. Start the application

From the EC2 project directory:

```bash
bash deploy/ec2/deploy.sh
```

This will build and start:

- nginx reverse proxy
- Next.js dashboard
- Node.js backend
- MongoDB

## 11. Check that the containers are running

Run:

```bash
docker ps
```

You should see containers for:

- `carelypet-proxy`
- `carelypet-dashboard`
- `carelypet-backend`
- `carelypet-mongo`

## 12. Test the deployment in your browser

Open:

```text
http://YOUR_ELASTIC_IP/
```

Also test:

```text
http://YOUR_ELASTIC_IP/api-docs
```

If the site loads and API docs open, the HTTP deployment is working.

## 13. Point your domain to the Elastic IP

In your DNS provider:

- create an `A` record for your domain
- point it to the Elastic IP

Example:

- `carelypet.com -> YOUR_ELASTIC_IP`
- `www.carelypet.com -> YOUR_ELASTIC_IP` if needed

Wait for DNS propagation.

## 14. Enable HTTPS with Let’s Encrypt

After the domain points to the EC2 instance, run:

```bash
bash deploy/ec2/enable-https.sh your-domain.com admin@your-domain.com
```

Example:

```bash
bash deploy/ec2/enable-https.sh carelypet.com admin@carelypet.com
```

This will:

- request the certificate
- start the HTTPS proxy config
- start automatic renewal with Certbot

## 15. Deploy future updates

Whenever you push changes and want to redeploy on EC2:

```bash
cd ~/carelypet
git pull origin main
bash deploy/ec2/deploy.sh --https
```

If HTTPS is not enabled yet, use:

```bash
bash deploy/ec2/deploy.sh
```

## 16. Useful troubleshooting commands

Check running containers:

```bash
docker ps
```

Check all containers, including stopped ones:

```bash
docker ps -a
```

See logs for proxy:

```bash
docker logs carelypet-proxy --tail 100
```

See logs for backend:

```bash
docker logs carelypet-backend --tail 100
```

See logs for dashboard:

```bash
docker logs carelypet-dashboard --tail 100
```

See logs for MongoDB:

```bash
docker logs carelypet-mongo --tail 100
```

Restart the whole stack:

```bash
docker compose down
docker compose up -d --build
```

Restart with HTTPS overlay:

```bash
docker compose -f docker-compose.yml -f docker-compose.https.yml up -d --build
```

## 17. GitHub Actions deployment

If you want GitHub to deploy automatically after push to `main`, set these GitHub repository secrets:

- `EC2_HOST`
- `EC2_USERNAME`
- `EC2_SSH_PRIVATE_KEY`
- `EC2_APP_DIR`

The workflow file already exists in:

- `.github/workflows/deploy-ec2.yml`

Set:

- `EC2_HOST` = your Elastic IP or domain
- `EC2_USERNAME` = `ubuntu`
- `EC2_APP_DIR` = `/home/ubuntu/carelypet`
- `EC2_SSH_PRIVATE_KEY` = contents of your private key

## 18. Recommended first deployment order

Use this exact order:

1. Connect to EC2 from WSL.
2. Clone the repo on EC2.
3. Run `sudo bash deploy/ec2/setup-ec2.sh`.
4. Reconnect to EC2.
5. Create `.env` and `carelypet-backend/.env`.
6. Run `bash deploy/ec2/deploy.sh`.
7. Test using the Elastic IP.
8. Point domain DNS to the Elastic IP.
9. Run `bash deploy/ec2/enable-https.sh your-domain.com admin@your-domain.com`.
10. For later releases, run `bash deploy/ec2/deploy.sh --https`.

## 19. Important warning

Your backend depends on several real secrets:

- JWT secret
- AWS S3 credentials
- Resend credentials
- Stripe credentials
- Firebase-related values if those features are used

Use fresh production secrets. Do not reuse test or leaked values.
