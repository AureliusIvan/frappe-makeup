# ERPNext & Frappe Docker

This repository contains the Dockerfile and docker-compose.yml to run ERPNext and Frappe in Docker containers.

## Installation

1. Clone this repository
2. Copy the `.env.example` file to `.env` and fill in the required values
3. Run `make up` to start the containers (this will take a while the first time)
4. Open `http://localhost:8000` in your browser
5. Follow the setup wizard to complete the installation
6. Enjoy!

## Usage

- `make up` to start the containers
- `make up-rebuild` to rebuild the containers and start them