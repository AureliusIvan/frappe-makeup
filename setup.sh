#!/bin/bash

# Install bench
bench init frappe-bench --frappe-branch v15.30.0 --python python3
bench set-config -g db_host mariadb;
bench set-config -gp db_port 3306;
bench set-config -g redis_cache "redis://redis-cache";
bench set-config -g redis_queue "redis://redis-queue";
bench set-config -g redis_socketio "redis://redis-queue";
cd frappe-bench && bench new-site localhost --mariadb-root-password admin --admin-password 123
bench get-app erpnext --branch version-15
bench --site localhost install-app erpnext