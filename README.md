# ERPNext & Frappe Docker

This repository contains the Dockerfile and docker-compose.yml to run ERPNext and Frappe in Docker containers.

## Installation

1. Clone this repository
2. Run `make up` to start the containers (this will take a while the first time)
3. Open `http://localhost:8000` in your browser
4. Follow the setup wizard to complete the installation
5. Enjoy!

## Usage

- `make up` to start the containers
- `make up-rebuild` to rebuild the containers and start them