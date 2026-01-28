---
description: Deploy Astro Project to AWS using GitHub and Helper Script
---

# AWS Production Deployment Guide (Automated)

This guide assumes you have pushed your code to a GitHub repository.

## 1. Push Code to GitHub (Local Machine)

If you haven't initialized git yet:
```bash
git init
git add .
git commit -m "Prepare for deployment"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/<REPO_NAME>.git
git push -u origin main
```

## 2. Server Setup (On AWS)

Connect to your AWS server:
```bash
ssh -i your-key.pem ubuntu@your-server-ip
```

### Install Docker Itself (If not installed)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
# IMPORTANT: Logout and Login again for permissions to take effect
exit
ssh -i your-key.pem ubuntu@your-server-ip
```

## 3. Pull and Run Setup Script

Clone your repo:
```bash
git clone https://github.com/<YOUR_USERNAME>/<REPO_NAME>.git astro_project
cd astro_project/backend
```

Run the automated setup script. This will:
- Generate a secure `.env` file automatically.
- Build and start the Docker containers.
- Migrate the database.
- **Create the Admin User** (admin / Yakut18!).

```bash
python3 production_setup.py
```

## 4. SSL Certification (Manual Step Required)

The script cannot automate the SSL certification challenge because it requires interaction. Run this manually:

```bash
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot -d astrorehberi.com -d www.astrorehberi.com
```

## 5. Enable HTTPS

Update Nginx config to use the new certificates.
Open `nginx/default.conf` and replace its content with the **Secure Config** found in the previous guide (Step 5 of original instruction), or simply edit it:

```bash
nano nginx/default.conf
```
(Paste the secure configuration block).

Then restart Nginx:
```bash
docker-compose restart nginx
```

## 6. Verification
- Visit `https://astrorehberi.com/admin/`
- Login with:
  - User: `admin`
  - Pass: `Yakut18!`
