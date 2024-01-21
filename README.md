# Standalone Unifi Controller

## Overview
This Dockerized Unifi Controller project is designed to simplify network setups by consolidating network services onto a single system. Utilizing extensive insights from Ubiquiti's documentation and a thorough analysis of the Unifi Cloud Key Gen 2, it offers a robust, Debian Bullseye-based solution. Special attention has been given to folder structure and package selection to ensure compatibility and an optimal user experience. Additionally, this project diverges from the typical Unifi Controller setup by requiring MongoDB to run in a separate container, adhering to best practices in containerized infrastructure management.

## Features
- **Docker-Based Unifi Controller**: Streamlines network management by reducing physical hardware needs.
- **Informed by Ubiquiti's Official Documentation**: Developed with insights from comprehensive research.
- **Optimized for Debian Bullseye**: Configured to align with Debian Bullseye for stability and compatibility.
- **Separate MongoDB Instance**: Aligns with containerized infrastructure best practices for better scalability and manageability.
- **User-Friendly Experience**: Ensures a smooth, hassle-free setup and operational process.
- **Secure and Reliable**: Focuses on security, following best practices for container and network safety.

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

## Configuration
Detailed setup instructions for the Unifi Controller and MongoDB, including environment variables, folder structures, and package installations.

## Support and Contribution
Guidelines for community involvement, issue reporting, feature requests, and improvements are welcomed.

## License
MIT License - This project is freely usable, modifiable, and distributable under the terms specified in the LICENSE file.
