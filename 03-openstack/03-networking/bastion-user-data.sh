#!/bin/bash
# Bastion host user data script
# Configures the bastion as a jump server and management host

# Set hostname
hostnamectl set-hostname "${hostname}"

# Update system
apt-get update

# Install essential packages for bastion host
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    git \
    nginx \
    python3 \
    python3-pip \
    net-tools \
    tcpdump \
    nmap \
    iptables-persistent \
    fail2ban

# Configure nginx for bastion dashboard
systemctl enable nginx
systemctl start nginx

# Create bastion dashboard
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Bastion Host - Network Management</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            color: white;
        }
        .container { 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 10px; 
            backdrop-filter: blur(10px);
        }
        .status { color: #27ae60; }
        .info { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 5px; margin: 15px 0; }
        pre { background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; overflow-x: auto; }
        .command { background: rgba(52, 152, 219, 0.2); padding: 10px; border-radius: 5px; margin: 10px 0; }
        .warning { background: rgba(231, 76, 60, 0.2); padding: 10px; border-radius: 5px; margin: 10px 0; }
        h3 { color: #3498db; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ Bastion Host Dashboard</h1>
        <p class="status">✅ Bastion Host is operational and ready for secure access</p>
        
        <div class="info">
            <h3>🏷️ Bastion Information</h3>
            <p><strong>Hostname:</strong> ${hostname}</p>
            <p><strong>Role:</strong> Jump Server & Network Management</p>
            <p><strong>Purpose:</strong> Secure access to private network resources</p>
        </div>
        
        <div class="grid">
            <div class="info">
                <h3>🔧 Installed Tools</h3>
                <ul>
                    <li>SSH Server (Port 22)</li>
                    <li>Network scanning (nmap)</li>
                    <li>Traffic analysis (tcpdump)</li>
                    <li>System monitoring (htop)</li>
                    <li>Intrusion prevention (fail2ban)</li>
                    <li>Web dashboard (nginx)</li>
                </ul>
            </div>
            
            <div class="info">
                <h3>🌐 Network Access</h3>
                <ul>
                    <li>External IP: Available</li>
                    <li>Web Subnet: 10.0.1.0/24</li>
                    <li>DB Subnet: 10.0.2.0/24</li>
                    <li>SSH Tunneling: Enabled</li>
                    <li>Port Forwarding: Available</li>
                </ul>
            </div>
        </div>
        
        <div class="info">
            <h3>📋 Network Status</h3>
            <pre id="network-status">Loading network information...</pre>
        </div>
        
        <div class="info">
            <h3>🔍 Connection Examples</h3>
            <div class="command">
                <strong>SSH to Web Server via Bastion:</strong><br>
                <code>ssh -o ProxyCommand='ssh -W %h:%p ubuntu@bastion-ip' ubuntu@web-server-ip</code>
            </div>
            <div class="command">
                <strong>SSH Tunnel for Database Access:</strong><br>
                <code>ssh -L 3306:db-server:3306 ubuntu@bastion-ip</code>
            </div>
            <div class="command">
                <strong>Network Scan from Bastion:</strong><br>
                <code>nmap -sn 10.0.1.0/24</code>
            </div>
        </div>
        
        <div class="warning">
            <h3>⚠️ Security Notes</h3>
            <ul>
                <li>This bastion host provides secure access to private network resources</li>
                <li>All connections are logged and monitored</li>
                <li>Use SSH key authentication only</li>
                <li>Fail2ban is protecting against brute force attacks</li>
            </ul>
        </div>
        
        <p><em>This dashboard was generated during bastion host initialization.</em></p>
    </div>
    
    <script>
        fetch('/network-status')
            .then(response => response.text())
            .then(data => document.getElementById('network-status').textContent = data)
            .catch(() => document.getElementById('network-status').textContent = 'Network status endpoint not available');
    </script>
</body>
</html>
EOF

# Create network status endpoint
cat > /var/www/html/network-status << 'EOF'
#!/bin/bash
echo "Content-Type: text/plain"
echo ""
echo "=== BASTION NETWORK STATUS ==="
echo "Hostname: $(hostname)"
echo "Interfaces:"
ip addr show | grep -E '^[0-9]+:|inet ' | sed 's/^/  /'
echo ""
echo "Routing table:"
ip route show | sed 's/^/  /'
echo ""
echo "Active connections:"
ss -tuln | head -20 | sed 's/^/  /'
echo ""
echo "Network reachability tests:"
echo "  Web subnet gateway: $(ping -c 1 10.0.1.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL")"
echo "  DB subnet gateway: $(ping -c 1 10.0.2.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL")"
echo "  External connectivity: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "OK" || echo "FAIL")"
EOF

chmod +x /var/www/html/network-status

# Configure nginx to serve scripts
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ ^/(network-status)$ {
        gzip off;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF

# Install fcgiwrap
apt-get install -y fcgiwrap
systemctl enable fcgiwrap
systemctl start fcgiwrap

# Configure fail2ban for SSH protection
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Configure SSH for better security
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Add SSH hardening
cat >> /etc/ssh/sshd_config << 'EOF'

# Bastion host SSH hardening
ClientAliveInterval 300
ClientAliveCountMax 2
MaxStartups 10:30:60
LoginGraceTime 60
Protocol 2
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel no
EOF

systemctl restart sshd
systemctl restart nginx

# Create useful scripts for network management
mkdir -p /opt/bastion-tools

cat > /opt/bastion-tools/network-scan.sh << 'EOF'
#!/bin/bash
echo "=== NETWORK DISCOVERY SCAN ==="
echo "Scanning web subnet (10.0.1.0/24)..."
nmap -sn 10.0.1.0/24 | grep -E "Nmap scan report|MAC Address"
echo ""
echo "Scanning database subnet (10.0.2.0/24)..."
nmap -sn 10.0.2.0/24 | grep -E "Nmap scan report|MAC Address"
EOF

cat > /opt/bastion-tools/connectivity-test.sh << 'EOF'
#!/bin/bash
echo "=== CONNECTIVITY TEST ==="
echo "Testing connectivity to common services..."

# Test web servers
for ip in 10.0.1.20 10.0.1.21; do
    echo -n "Web server $ip HTTP: "
    curl -s --connect-timeout 3 http://$ip > /dev/null && echo "OK" || echo "FAIL"
    echo -n "Web server $ip SSH: "
    nc -z -w3 $ip 22 && echo "OK" || echo "FAIL"
done

# Test database servers
for ip in 10.0.2.20; do
    echo -n "Database server $ip SSH: "
    nc -z -w3 $ip 22 && echo "OK" || echo "FAIL"
    echo -n "Database server $ip MySQL: "
    nc -z -w3 $ip 3306 && echo "OK" || echo "FAIL"
done
EOF

chmod +x /opt/bastion-tools/*.sh

# Create MOTD
cat > /etc/motd << 'EOF'

  ╔══════════════════════════════════════════════════════════════════╗
  ║   🛡️  BASTION HOST - SECURE NETWORK ACCESS POINT               ║
  ║                                                                  ║
  ║   This is a secure bastion host for accessing private network   ║
  ║   resources. All connections are monitored and logged.          ║
  ║                                                                  ║
  ║   Available tools:                                               ║
  ║   • /opt/bastion-tools/network-scan.sh                          ║
  ║   • /opt/bastion-tools/connectivity-test.sh                     ║
  ║   • nmap, tcpdump, htop, fail2ban                               ║
  ║                                                                  ║
  ║   Web dashboard: http://[bastion-public-ip]                      ║
  ║                                                                  ║
  ║   Security features:                                             ║
  ║   • SSH key authentication only                                 ║
  ║   • Fail2ban intrusion prevention                               ║
  ║   • Connection logging and monitoring                           ║
  ╚══════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Bastion host configuration completed" >> /var/log/terraform-init.log
touch /var/lib/cloud/bastion-init-complete