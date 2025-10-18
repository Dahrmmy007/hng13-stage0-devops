# HNG 13 DevOps Stage 0

Name: Ologbon Damilola
Slack Username:@Damien 

## Project Description

This repository contains my submission for the **HNG 13 Stage 0 DevOps task**.  
The project involves setting up a simple server, deploying it, and linking it to this GitHub repository.  
It demonstrates basic DevOps workflow skills, including:
The project demonstrates:
- Basic server setup and deployment workflow  
- Proper version control and documentation practices  
- Clear communication through well-structured repository content
  
**Server IP/Domain:** (Add this after deployment)

**Server URL:** http://13.49.241.144/

## Deployment Details
- Platform: AWS EC2
- Web Server: NGINX
- Port: 80 (HTTP)

## Part 2: AWS EC2 Setup

Here's how to set up your AWS instance:

### Step 1: Launch EC2 Instance

1. **Log into AWS Console:**
   - Go to AWS Console → EC2 → Launch Instance

2. **Configure Instance:**
   - **Name:** `hng13-stage0-devops`
   - **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance Type:** t2.micro (Free tier)
   - **Key Pair:** Create new or use existing (you'll need this to SSH)

### Step 2: Configure Security Group (CRITICAL!)

This is where you set your firewall rules:

**Security Group Inbound Rules:**
1. SSH:
   - Type: SSH
   - Protocol: TCP
   - Port: 22
   - Source: Your IP (or 0.0.0.0/0 for anywhere - less secure)

2. HTTP:
   - Type: HTTP
   - Protocol: TCP
   - Port: 80
   - Source: 0.0.0.0/0 (allow from anywhere)
