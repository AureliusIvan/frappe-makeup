FROM frappe/bench:v5.24.1

# Install redis-server
USER root
RUN apt-get update && apt-get install -y redis-server

# give frappe permission to create or remove files in the /home/frappe directory
RUN chown -R frappe:frappe /home/frappe

# change user to frappe
USER frappe

WORKDIR /home/frappe