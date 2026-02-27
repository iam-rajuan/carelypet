# EC2 Deploy Checklist

Use this after:

- EC2 instance is created
- Elastic IP is attached
- security group allows `22`, `80`, `443`

## 1. From WSL, prepare SSH key

```bash
mkdir -p ~/.ssh
cp /mnt/c/Users/YOUR_WINDOWS_USER/Downloads/your-key.pem ~/.ssh/carelypet-ec2.pem
chmod 400 ~/.ssh/carelypet-ec2.pem
```

## 2. Connect to EC2

```bash
ssh -i ~/.ssh/carelypet-ec2.pem ubuntu@YOUR_ELASTIC_IP
```

## 3. Install git

```bash
sudo apt update && sudo apt install -y git
```

## 4. Clone repo

```bash
cd ~
git clone YOUR_REPOSITORY_URL carelypet
cd carelypet
```

## 5. Install Docker

```bash
sudo bash deploy/ec2/setup-ec2.sh
```

## 6. Reconnect

```bash
exit
ssh -i ~/.ssh/carelypet-ec2.pem ubuntu@YOUR_ELASTIC_IP
cd ~/carelypet
```

## 7. Create env files

```bash
cp .env.example .env
cp carelypet-backend/.env.example carelypet-backend/.env
```

## 8. Edit root env

```bash
nano .env
```

Use:

```env
PROXY_PORT=80
NEXT_PUBLIC_API_BASE_URL=/api/v1
DOMAIN_NAME=
LETSENCRYPT_EMAIL=
HTTPS_PORT=443
```

## 9. Edit backend env

```bash
nano carelypet-backend/.env
```

Set real values for:

```env
NODE_ENV=production
BASE_URL=/api/v1
PORT=5191
MONGO_URI=mongodb://mongo:27017/carelypet_db
JWT_SECRET=your-secret
JWT_EXPIRES_IN=7d
ACCESS_TOKEN_EXPIRES_IN=480m
REFRESH_TOKEN_EXPIRES_IN=7d
SETUP_TOKEN_EXPIRES_IN=30m
ADMIN_PASSWORD=your-admin-password
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_BUCKET_NAME=your-bucket
AWS_REGION=your-region
RESEND_API_KEY=your-key
RESEND_FROM=your-email
STRIPE_SECRET_KEY=your-key
STRIPE_WEBHOOK_SECRET=your-secret
STRIPE_CURRENCY=usd
ORG_NAME=Carely Pets
FIREBASE_WEB_API_KEY=your-key
```

## 10. First deploy

```bash
bash deploy/ec2/deploy.sh
```

## 11. Check containers

```bash
docker ps
```

## 12. Test in browser

```text
http://YOUR_ELASTIC_IP/
http://YOUR_ELASTIC_IP/api-docs
```

## 13. Point domain to Elastic IP

Create DNS `A` record:

- `your-domain.com -> YOUR_ELASTIC_IP`

## 14. Enable HTTPS

After DNS is ready:

```bash
bash deploy/ec2/enable-https.sh your-domain.com admin@your-domain.com
```

## 15. Future deploys

```bash
cd ~/carelypet
git pull origin main
bash deploy/ec2/deploy.sh --https
```

## 16. Useful logs

```bash
docker logs carelypet-proxy --tail 100
docker logs carelypet-backend --tail 100
docker logs carelypet-dashboard --tail 100
docker logs carelypet-mongo --tail 100
```
