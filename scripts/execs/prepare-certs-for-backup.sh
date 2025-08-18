#!/bin/bash

CERT_DIR=~/NewBiz/certs

echo "📦 Relaxing permissions in $CERT_DIR to allow backup..."

# 1. Make the directory accessible
chmod 755 "$CERT_DIR"

# 2. Make all files readable for backup (but still not world-writable)
chmod 644 "$CERT_DIR"/*.pem

echo "✅ Permissions relaxed. Safe to back up."
ls -l "$CERT_DIR"
