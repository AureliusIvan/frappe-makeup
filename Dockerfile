FROM frappe/bench:v5.22.6

# Install redis-server
USER root
RUN apt-get update && apt-get install -y redis-server

USER frappe
WORKDIR /home/frappe