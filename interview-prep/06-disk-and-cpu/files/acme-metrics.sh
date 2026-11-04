#!/bin/bash
logger_line="$(date -Is) component=acme metric=heartbeat"
printf '%s\n' "$logger_line" >> /var/log/acme/metrics.log
