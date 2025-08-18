#!/bin/bash

CERT_DIR=~/NewBiz/certs

echo "🔐 Fixing permissions in $CERT_DIR..."

# 1. Directory permissions (only owner can access)
chmod 700 "$CERT_DIR"

# 2. Private keys (only owner can read/write)
chmod 600 "$CERT_DIR"/*key.pem

# 3. Public certs (readable by others if needed)
chmod 644 "$CERT_DIR"/*-cert.pem "$CERT_DIR"/ca.pem "$CERT_DIR"/aiven-ca.pem 2>/dev/null

echo "✅ Permissions updated:"
ls -l "$CERT_DIR"
