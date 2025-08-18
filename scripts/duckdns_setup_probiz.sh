#!/bin/bash
# Complete DuckDNS Setup Script for probiz.duckdns.org
# Run this script on your Oracle Cloud server

set -e  # Exit on any error

echo "=========================================="
echo "    DuckDNS Setup for ProBiz Server"
echo "=========================================="

# Configuration - EDIT THESE VALUES
DOMAIN="probiz"  # Your subdomain (without .duckdns.org)
TOKEN="37ba0208-5376-4824-bb55-4043de48dcfd"  # Get this from duckdns.org after signing in
IP="144.24.7.55"  # Your Oracle Cloud IP
EMAIL="pojamma.apps@gmail.com"  # Your email for SSL certificate

# Check if token was updated
if [ "$TOKEN" = "PUT_YOUR_DUCKDNS_TOKEN_HERE" ]; then
    echo "❌ ERROR: You need to edit this script first!"
    echo ""
    echo "1. Go to https://www.duckdns.org"
    echo "2. Sign in with Google/GitHub/Reddit/Twitter"
    echo "3. Create subdomain: $DOMAIN"
    echo "4. Copy your token from the website"
    echo "5. Edit this script and replace 'PUT_YOUR_DUCKDNS_TOKEN_HERE' with your actual token"
    echo ""
    exit 1
fi

echo "Configuration:"
echo "Domain: $DOMAIN.duckdns.org"
echo "IP: $IP"
echo "Email: $EMAIL"
echo ""

# Create DuckDNS directory
echo "📁 Creating DuckDNS directory..."
mkdir -p /home/opc/duckdns
cd /home/opc/duckdns

# Create the update script
echo "📝 Creating DuckDNS update script..."
cat > duck.sh << EOF
#!/bin/bash
# DuckDNS Update Script for $DOMAIN.duckdns.org

DOMAIN="$DOMAIN"
TOKEN="$TOKEN"
IP="$IP"

echo "Updating DuckDNS: \$DOMAIN.duckdns.org -> \$IP"
RESPONSE=\$(curl -s "https://www.duckdns.org/update?domains=\$DOMAIN&token=\$TOKEN&ip=\$IP")

if [ "\$RESPONSE" = "OK" ]; then
    echo "\$(date): DuckDNS update successful" >> /home/opc/duckdns/duck.log
    echo "✅ Update successful"
    exit 0
else
    echo "\$(date): DuckDNS update failed: \$RESPONSE" >> /home/opc/duckdns/duck.log
    echo "❌ Update failed: \$RESPONSE"
    exit 1
fi
EOF

# Make update script executable
chmod +x duck.sh

echo "🔄 Testing initial DuckDNS update..."
if ./duck.sh; then
    echo "✅ DuckDNS update successful!"
else
    echo "❌ DuckDNS update failed. Please check your token and domain."
    exit 1
fi

# Wait a moment for DNS propagation
echo "⏳ Waiting 10 seconds for DNS propagation..."
sleep 10

# Test DNS resolution
echo "🔍 Testing DNS resolution..."
if nslookup $DOMAIN.duckdns.org | grep -q "$IP"; then
    echo "✅ DNS resolution working: $DOMAIN.duckdns.org -> $IP"
else
    echo "⚠️  DNS might still be propagating. This is normal and should work within a few minutes."
fi

# Set up cron job for automatic updates
echo "⏰ Setting up automatic updates..."
# Remove any existing cron job for duck.sh
(crontab -l 2>/dev/null | grep -v "/home/opc/duckdns/duck.sh"; echo "*/5 * * * * /home/opc/duckdns/duck.sh >/dev/null 2>&1") | crontab -

# Create status check script
echo "📊 Creating status check script..."
cat > check_status.sh << EOF
#!/bin/bash
# DuckDNS Status Check Script

echo "=========================================="
echo "    DuckDNS Status for $DOMAIN.duckdns.org"
echo "=========================================="

echo "Current IP: $IP"
echo "Domain: $DOMAIN.duckdns.org"
echo ""

echo "🔍 DNS Resolution:"
nslookup $DOMAIN.duckdns.org

echo ""
echo "📡 Testing HTTP connection:"
curl -s -I http://$DOMAIN.duckdns.org | head -1 || echo "HTTP connection failed"

echo ""
echo "🔒 Testing HTTPS connection:"
curl -s -I https://$DOMAIN.duckdns.org | head -1 || echo "HTTPS not configured yet"

echo ""
echo "📋 Recent update log:"
tail -5 /home/opc/duckdns/duck.log 2>/dev/null || echo "No log entries yet"

echo ""
echo "⏰ Cron job status:"
crontab -l | grep duck.sh || echo "No cron job found"
EOF

chmod +x check_status.sh

# Create manual update script
echo "🔧 Creating manual update script..."
cat > manual_update.sh << EOF
#!/bin/bash
# Manual DuckDNS Update Script

echo "Manually updating DuckDNS..."
/home/opc/duckdns/duck.sh

echo ""
echo "Checking status:"
/home/opc/duckdns/check_status.sh
EOF

chmod +x manual_update.sh

# Create uninstall script
echo "🗑️ Creating uninstall script..."
cat > uninstall.sh << EOF
#!/bin/bash
# DuckDNS Uninstall Script

echo "Removing DuckDNS setup..."

# Remove cron job
crontab -l 2>/dev/null | grep -v "/home/opc/duckdns/duck.sh" | crontab -

echo "✅ Cron job removed"
echo "📁 Directory /home/opc/duckdns preserved (delete manually if needed)"
echo "🔧 You may need to manually update your nginx configuration"
EOF

chmod +x uninstall.sh

# Create info file
cat > setup_info.txt << EOF
DuckDNS Setup Information
========================

Domain: $DOMAIN.duckdns.org
IP: $IP
Email: $EMAIL
Setup Date: $(date)

Files Created:
- duck.sh: Main update script (runs every 5 minutes via cron)
- check_status.sh: Check DNS and connection status
- manual_update.sh: Force an immediate update
- uninstall.sh: Remove DuckDNS setup
- duck.log: Update history log

Useful Commands:
- Check status: ./check_status.sh
- Manual update: ./manual_update.sh
- View logs: tail -f duck.log
- Test DNS: nslookup $DOMAIN.duckdns.org

Next Steps:
1. Install SSL certificate: sudo certbot --nginx -d $DOMAIN.duckdns.org
2. Update nginx configuration to use the domain
3. Test your website: https://$DOMAIN.duckdns.org
EOF

echo ""
echo "🎉 DuckDNS setup completed successfully!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "   Domain: $DOMAIN.duckdns.org"
echo "   Points to: $IP"
echo "   Auto-update: Every 5 minutes"
echo ""
echo "📁 Files created in /home/opc/duckdns/:"
echo "   • duck.sh (main update script)"
echo "   • check_status.sh (status checker)"
echo "   • manual_update.sh (manual update)"
echo "   • uninstall.sh (removal script)"
echo "   • setup_info.txt (this information)"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: cd /home/opc/duckdns && ./check_status.sh"
echo "   Manual update: cd /home/opc/duckdns && ./manual_update.sh"
echo "   View logs: cd /home/opc/duckdns && tail -f duck.log"
echo ""
echo "✅ Next steps:"
echo "   1. Test DNS: nslookup $DOMAIN.duckdns.org"
echo "   2. Get SSL certificate: sudo certbot --nginx -d $DOMAIN.duckdns.org --email $EMAIL"
echo "   3. Update nginx config to use your domain"
echo "   4. Visit: https://$DOMAIN.duckdns.org"
echo ""
echo "=========================================="

# Run initial status check
echo "🔍 Running initial status check..."
./check_status.sh