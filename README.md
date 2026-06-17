# 🚀 Production CI/CD Pipeline — Node.js → AWS ECR + EC2

![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?style=flat&logo=amazonaws&logoColor=black)
![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Runtime-Node.js_18-339933?style=flat&logo=nodedotjs&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

A **production-grade CI/CD pipeline** that automatically builds, tests, and deploys a Node.js application to AWS — with staging/production environments, health-check-based rollback, and Slack notifications.

> 🎯 **This is a portfolio demo** showing exactly what I deliver to clients. Every component here mirrors a real production setup.

---

## 📐 Architecture

```
Developer pushes code
        │
        ▼
┌───────────────────┐
│   GitHub Actions  │  ← Triggered on push to develop/main
└─────────┬─────────┘
          │
    ┌─────▼──────┐
    │  Job 1     │  Lint + Jest Tests
    │  CI Checks │  (runs on every push & PR)
    └─────┬──────┘
          │ pass
    ┌─────▼──────────────┐
    │  Job 2             │  Multi-stage Docker build
    │  Build & Push      │  → Push to AWS ECR
    │  to ECR            │  Tagged: branch-sha8
    └─────┬──────────────┘
          │
    ┌─────┴─────────────────────────┐
    │                               │
    ▼ (push to develop)             ▼ (push to main)
┌──────────────┐            ┌───────────────────┐
│  Job 3       │            │  Job 4            │
│  Deploy to   │            │  Manual Approval  │
│  STAGING     │            │  ↓                │
│  EC2         │            │  Deploy to PROD   │
└──────┬───────┘            │  EC2              │
       │                    └────────┬──────────┘
       ▼                             ▼
 Health Check                  Health Check
 /health → 200?                /health → 200?
       │                             │
    ✅ pass                       ✅ pass
  Keep new image               Keep new image
       │                             │
    ❌ fail                       ❌ fail
  Auto-rollback                Auto-rollback
  to previous image            to previous image
       │                             │
       └──────────┬──────────────────┘
                  ▼
         Slack Notification
         (success or failure)
```

---

## ✨ What This Pipeline Does

| Feature | Details |
|---|---|
| **Auto-trigger** | Push to `develop` → staging. Push to `main` → production (with approval) |
| **Multi-stage Docker build** | Runs tests inside Docker build, non-root user, minimal image size |
| **AWS ECR** | Images tagged `branch-sha8` + `branch-latest` for easy tracking |
| **Health check rollback** | 10 retries over 50s — if app doesn't respond, auto-reverts to last good image |
| **Slack alerts** | Notifies on every deploy (success ✅ or failure ❌) with commit & author |
| **Security** | Least-privilege IAM, secrets via GitHub Secrets, no hardcoded credentials |

---

## 🗂 Project Structure

```
nodejs-cicd-aws/
├── .github/
│   └── workflows/
│       └── cicd.yml          # ← The entire pipeline
├── src/
│   ├── app.js                # Express API
│   └── app.test.js           # Jest tests
├── scripts/
│   ├── setup-ec2.sh          # Run once on new EC2 instance
│   └── setup-aws.sh          # Creates ECR repo + IAM user
├── Dockerfile                # Multi-stage production build
├── package.json
└── .gitignore
```

---

## 🚀 How to Set This Up (Step by Step)

### Step 1 — Fork & clone this repo
```bash
git clone https://github.com/BhavikaChauhan/nodejs-cicd-aws.git
cd nodejs-cicd-aws
```

### Step 2 — Create AWS resources
```bash
# Make sure AWS CLI is configured (aws configure)
chmod +x scripts/setup-aws.sh
./scripts/setup-aws.sh
# Copy the output — you'll need the keys for GitHub Secrets
```

### Step 3 — Launch 2 EC2 instances (t2.micro — free tier)
- AMI: Ubuntu 22.04 LTS
- Type: t2.micro
- Security Group: open ports 22 (SSH), 80 (HTTP), 3000 (app)
- Create/download a `.pem` key pair

Run on both instances:
```bash
chmod +x scripts/setup-ec2.sh
sudo ./scripts/setup-ec2.sh
```

### Step 4 — Add GitHub Secrets
Go to your repo → **Settings → Secrets and variables → Actions**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | From setup-aws.sh output |
| `AWS_SECRET_ACCESS_KEY` | From setup-aws.sh output |
| `STAGING_EC2_IP` | Public IP of staging EC2 |
| `PROD_EC2_IP` | Public IP of production EC2 |
| `EC2_SSH_KEY` | Full contents of your `.pem` file |
| `SLACK_WEBHOOK_URL` | From Slack → Apps → Incoming Webhooks |

### Step 5 — Configure production approval gate
Go to **Settings → Environments → production → Required reviewers**
Add yourself — this creates the manual approval step before prod deploys.

### Step 6 — Trigger your first deploy
```bash
git checkout -b develop
git push origin develop
# Watch the Actions tab — staging deploy fires automatically
```

---

## 🔁 Branch Strategy

| Branch | Deploys to | Approval needed? |
|---|---|---|
| `develop` | Staging EC2 | No — automatic |
| `main` | Production EC2 | Yes — manual approval |
| `feature/*` | Nowhere | Runs tests only |

---

## 📡 API Endpoints

Once deployed, these endpoints are available:

```
GET /          → App info + version + environment
GET /health    → Health check (used by pipeline rollback logic)
GET /api/products      → List all products
GET /api/products/:id  → Single product by ID
```

Test locally:
```bash
npm install
npm test          # Run Jest tests
npm start         # Start on localhost:3000
curl localhost:3000/health
```

---

## 💰 AWS Cost

Running this demo costs approximately **₹0/month** on AWS free tier:
- EC2 t2.micro: 750 hrs/month free (12 months)
- ECR: 500MB/month free
- Data transfer: 1GB/month free

> 💡 Stop EC2 instances when not demoing to clients. They only need to be running during live demos.

---

## 🧰 Tech Stack

- **Runtime:** Node.js 18 (Alpine)
- **Framework:** Express.js
- **Tests:** Jest + Supertest
- **CI/CD:** GitHub Actions
- **Registry:** AWS ECR
- **Compute:** AWS EC2 (Ubuntu 22.04)
- **Proxy:** Nginx
- **Notifications:** Slack Incoming Webhooks

---
About me
