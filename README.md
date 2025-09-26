# Standalone Unifi Network Controller

## Overview
This Dockerized Unifi Network Controller project is designed to simplify network setups by consolidating network services into a single system. Utilizing extensive insights from Ubiquiti's documentation and a thorough analysis of the Unifi Cloud Key Gen 2, it offers a robust, Debian Bookworm-based solution. Special attention has been given to folder structure and package selection to ensure compatibility and an optimal user experience. Additionally, this project diverges from the typical Unifi Controller setup by requiring MongoDB to run in a separate container, adhering to best practices in containerized infrastructure management.

## Features
- **Docker-Based Unifi Network Controller**: Streamlines network management by reducing physical hardware needs.
- **Informed by Ubiquiti's Official Documentation**: Developed with insights from comprehensive research.
- **Optimized for Debian Bookworm**: Built with a multi-stage image on Debian Bookworm for a current, security-supported base while keeping compatibility with the UniFi Network Application.
- **Separate MongoDB Instance**: Aligns with containerized infrastructure best practices for better scalability and manageability.
- **User-Friendly Experience**: Ensures a smooth, hassle-free setup and operational process.
- **Secure and Reliable**: Focuses on security, following best container and network safety practices.

## Requirements
- Docker and Docker Compose
- A separate MongoDB instance (containerized or standalone)
- Basic understanding of Docker containerization
- Familiarity with Unifi hardware network configurations

## Deployment Instructions
1. **Clone Repository**: `git clone [repository-url]`
2. **Configure**: Update the `.env` file with your network specifications.
3. **Deploy with Docker Compose**: Run `docker-compose up -d` to start the containers.
4. **Access and Setup**: Log into the Unifi Controller through the specified port to complete the setup.

## Release & Automation Workflow
- **Upstream Monitoring**: A scheduled GitHub Actions workflow (`Check for Upstream UniFi Version`) queries Ubiquiti's community GraphQL API for new UniFi Network Application GA releases.
- **Automated Update Pull Requests**: When a new version is detected, the workflow updates `Dockerfile` and `versions.txt`, opens a pull request labeled `automation`, and links back to the official [UniFi release notes](https://community.ui.com/releases).
- **Safety Checks**: The standard `Build` workflow runs linting, multi-arch builds, and an amd64 smoke test to verify the container before publication.
- **Auto Approval & Merge**: Successful builds trigger an auto-approval workflow that squashes the update PR once checks pass on the upstream repository.
- **Release Publishing**: After the PR merges, another workflow tags the repository, creates a GitHub release with links to the upstream announcement, and kicks off the Docker Hub publication pipeline.

## Configuration
Detailed setup instructions for the Unifi Controller and MongoDB, including environment variables, folder structures, and package installations.

## Support and Contribution
Guidelines for community involvement, issue reporting, feature requests, and improvements are welcomed.

## License
MIT License - This project is freely usable, modifiable, and distributable under the terms specified in the LICENSE file.
