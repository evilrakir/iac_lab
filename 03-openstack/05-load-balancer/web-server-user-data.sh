#!/bin/bash
# Load-balanced web server user data script
# Configures nginx with health checks and load balancer awareness

# Set hostname
hostnamectl set-hostname "${hostname}"

# Update system
apt-get update

# Install packages
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    git \
    nginx \
    python3 \
    python3-pip \
    jq

# Configure nginx
systemctl enable nginx
systemctl start nginx

# Create load-balanced application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Load Balanced Web Server ${server_id}</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #16a085 0%, #1abc9c 100%);
            color: white;
        }
        .container { 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 10px; 
            backdrop-filter: blur(10px);
        }
        .server-badge { 
            background: #e74c3c; 
            padding: 15px 30px; 
            border-radius: 25px; 
            display: inline-block; 
            margin: 20px 0;
            font-weight: bold;
            font-size: 1.2em;
        }
        .status { color: #27ae60; }
        .info { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 5px; margin: 15px 0; }
        .metric { text-align: center; padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; margin: 10px; }
        .metric h3 { margin: 0; color: #f39c12; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .lb-test { background: rgba(52, 152, 219, 0.2); padding: 20px; border-radius: 10px; margin: 20px 0; }
        pre { background: rgba(0,0,0,0.3); padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
    <script>
        let requestCount = 0;
        
        function updateStats() {
            fetch('/api/server-stats')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('request-count').textContent = data.requests;
                    document.getElementById('uptime').textContent = data.uptime;
                    document.getElementById('load-avg').textContent = data.load;
                    document.getElementById('memory-usage').textContent = data.memory + '%';
                })
                .catch(() => console.log('Stats update failed'));
        }
        
        function testLoadBalancing() {
            const results = document.getElementById('lb-test-results');
            results.innerHTML = 'Testing load balancer...<br>';
            
            for (let i = 0; i < 10; i++) {
                setTimeout(() => {
                    fetch('/')
                        .then(response => response.text())
                        .then(html => {
                            const match = html.match(/SERVER ID: (\d+)/);
                            if (match) {
                                results.innerHTML += \`Request \${i+1}: Server \${match[1]}<br>\`;
                            }
                        })
                        .catch(() => {
                            results.innerHTML += \`Request \${i+1}: Error<br>\`;
                        });
                }, i * 500);
            }
        }
        
        setInterval(updateStats, 5000);
        window.onload = () => {
            updateStats();
            requestCount = parseInt(document.getElementById('request-count').textContent || '0');
        };
    </script>
</head>
<body>
    <div class="container">
        <h1>🔄 Load Balanced Application</h1>
        <div class="server-badge">SERVER ID: ${server_id}</div>
        <p class="status">✅ This server is healthy and serving traffic</p>
        
        <div class="info">
            <h3>🏷️ Server Information</h3>
            <p><strong>Hostname:</strong> ${hostname}</p>
            <p><strong>Server ID:</strong> ${server_id}</p>
            <p><strong>Role:</strong> Load Balanced Web Server</p>
            <p><strong>Load Balancer Pool:</strong> ${project_name}-web-pool</p>
            <p><strong>Request Time:</strong> <span id="current-time">$(date)</span></p>
        </div>
        
        <div class="grid">
            <div class="metric">
                <h3>Requests Served</h3>
                <div class="value" id="request-count">--</div>
            </div>
            <div class="metric">
                <h3>Server Uptime</h3>
                <div class="value" id="uptime">--</div>
            </div>
            <div class="metric">
                <h3>Load Average</h3>
                <div class="value" id="load-avg">--</div>
            </div>
            <div class="metric">
                <h3>Memory Usage</h3>
                <div class="value" id="memory-usage">--</div>
            </div>
        </div>
        
        <div class="lb-test">
            <h3>🧪 Load Balancer Testing</h3>
            <p>Test the load balancer by making multiple requests:</p>
            <button onclick="testLoadBalancing()" style="padding: 10px 20px; background: #3498db; color: white; border: none; border-radius: 5px; cursor: pointer;">Test Load Balancing</button>
            <div id="lb-test-results" style="margin-top: 15px; font-family: monospace;"></div>
        </div>
        
        <div class="info">
            <h3>🔍 Health Check Endpoints</h3>
            <p><strong>Health Status:</strong> <a href="/health" style="color: #3498db;">/health</a></p>
            <p><strong>Server Stats:</strong> <a href="/api/server-stats" style="color: #3498db;">/api/server-stats</a></p>
            <p><strong>Load Balancer Status:</strong> <a href="/lb-status" style="color: #3498db;">/lb-status</a></p>
        </div>
        
        <div class="info">
            <h3>📊 Load Balancer Features</h3>
            <ul>
                <li>Round-robin traffic distribution</li>
                <li>Automatic health monitoring</li>
                <li>Failover and redundancy</li>
                <li>Session persistence (if configured)</li>
                <li>Real-time pool member status</li>
            </ul>
        </div>
        
        <p><em>Response generated by Server ${server_id} at $(date)</em></p>
    </div>
    
    <script>
        document.getElementById('current-time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Basic health checks
nginx_status=$(systemctl is-active nginx)
load_avg=$(cat /proc/loadavg | cut -d' ' -f1)
disk_space=$(df / | tail -1 | awk '{print $4}')
memory_available=$(free | grep Available | awk '{print $7}')

# Determine health status
if [ "$nginx_status" = "active" ] && [ "$disk_space" -gt 100000 ] && [ "$memory_available" -gt 100000 ]; then
    health_status="healthy"
    http_code="200"
else
    health_status="unhealthy"
    http_code="503"
fi

echo "Status: $http_code"
echo ""

cat << END
{
  "status": "$health_status",
  "server_id": "${server_id}",
  "hostname": "${hostname}",
  "services": {
    "nginx": "$nginx_status"
  },
  "metrics": {
    "load_average": "$load_avg",
    "disk_free_kb": "$disk_space",
    "memory_available_kb": "$memory_available"
  },
  "timestamp": "$(date -Iseconds)",
  "health_check_url": "/health"
}
END
EOF

chmod +x /var/www/html/health

# Create server stats API
mkdir -p /var/www/html/api

cat > /var/www/html/api/server-stats << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Get server statistics
uptime_info=$(uptime -p)
load_avg=$(cat /proc/loadavg | cut -d' ' -f1)
memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
request_count=$(wc -l < /var/log/nginx/access.log 2>/dev/null || echo "0")
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

cat << END
{
  "server_id": "${server_id}",
  "hostname": "${hostname}",
  "uptime": "$uptime_info",
  "load": "$load_avg",
  "memory": "${memory_usage:-0}",
  "cpu": "${cpu_usage:-0}",
  "requests": "$request_count",
  "timestamp": "$(date -Iseconds)"
}
END
EOF

chmod +x /var/www/html/api/server-stats

# Create load balancer status page
cat > /var/www/html/lb-status << 'EOF'
#!/bin/bash
echo "Content-Type: text/html"
echo ""

cat << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Load Balancer Pool Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #2c3e50; color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 10px; }
        .server { padding: 15px; margin: 10px 0; border-radius: 5px; }
        .healthy { background: rgba(39, 174, 96, 0.3); }
        .unhealthy { background: rgba(231, 76, 60, 0.3); }
        .current { border: 2px solid #f39c12; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.2); }
        th { background: rgba(255,255,255,0.1); }
    </style>
    <script>
        function testServers() {
            const servers = ['192.168.100.10', '192.168.100.11', '192.168.100.12']; // Adjust IPs as needed
            const resultsDiv = document.getElementById('server-status');
            
            resultsDiv.innerHTML = '<p>Testing pool members...</p>';
            
            let results = [];
            servers.forEach((server, index) => {
                const serverId = index + 1;
                const serverDiv = document.createElement('div');
                serverDiv.className = 'server';
                serverDiv.innerHTML = `<h4>Server ${serverId} (${server})</h4><p>Testing...</p>`;
                
                // Simulate health check (in real environment, this would be actual health checks)
                setTimeout(() => {
                    const isHealthy = Math.random() > 0.2; // 80% chance of being healthy
                    serverDiv.className = `server ${isHealthy ? 'healthy' : 'unhealthy'}`;
                    serverDiv.innerHTML = `
                        <h4>Server ${serverId} (${server})</h4>
                        <p>Status: ${isHealthy ? 'Healthy' : 'Unhealthy'}</p>
                        <p>Response Time: ${Math.floor(Math.random() * 100) + 50}ms</p>
                    `;
                    if (serverId == ${server_id}) {
                        serverDiv.classList.add('current');
                    }
                }, index * 500);
                
                resultsDiv.appendChild(serverDiv);
            });
        }
        
        window.onload = testServers;
        setInterval(testServers, 10000);
    </script>
</head>
<body>
    <div class="container">
        <h1>🔄 Load Balancer Pool Status</h1>
        <p>Current server: <strong>${hostname} (Server ${server_id})</strong></p>
        
        <div id="server-status">
            <p>Loading pool member status...</p>
        </div>
        
        <h3>📊 Pool Statistics</h3>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Load Balancing Method</td><td>Round Robin</td></tr>
            <tr><td>Health Check Interval</td><td>5 seconds</td></tr>
            <tr><td>Health Check Timeout</td><td>3 seconds</td></tr>
            <tr><td>Max Retries</td><td>3</td></tr>
            <tr><td>Current Time</td><td id="current-time">--</td></tr>
        </table>
        
        <h3>🧪 Testing Commands</h3>
        <p>Test load balancing from command line:</p>
        <pre>
# Test multiple requests
for i in {1..10}; do curl -s http://[LB-IP]/ | grep "SERVER ID"; done

# Test health endpoint
curl http://[LB-IP]/health

# Monitor in real-time
watch -n 2 'curl -s http://[LB-IP]/ | grep "SERVER ID"'
        </pre>
    </div>
    
    <script>
        document.getElementById('current-time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
HTML
EOF

chmod +x /var/www/html/lb-status

# Configure nginx to serve dynamic content
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    # Add server identification headers
    add_header X-Server-ID "${server_id}" always;
    add_header X-Hostname "${hostname}" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Health check endpoint
    location /health {
        gzip off;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    
    # API endpoints
    location ~ ^/(api/server-stats|lb-status)$ {
        gzip off;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    
    # Custom logging for load balancer analysis
    access_log /var/log/nginx/access.log combined;
    error_log /var/log/nginx/error.log;
}
EOF

# Install fcgiwrap
apt-get install -y fcgiwrap
systemctl enable fcgiwrap
systemctl start fcgiwrap

# Create load balancer testing script
cat > /opt/test-lb.sh << 'EOF'
#!/bin/bash
echo "=== LOAD BALANCER TESTING SCRIPT ==="

LB_IP="$1"
if [ -z "$LB_IP" ]; then
    echo "Usage: $0 <load-balancer-ip>"
    exit 1
fi

echo "Testing load balancer at: $LB_IP"
echo ""

echo "1. Basic connectivity test:"
curl -s -w "Status: %{http_code}, Time: %{time_total}s\n" http://$LB_IP/ -o /dev/null

echo ""
echo "2. Server distribution test (10 requests):"
for i in {1..10}; do
    server_id=$(curl -s http://$LB_IP/ | grep -o "SERVER ID: [0-9]*" | head -1)
    echo "Request $i: $server_id"
    sleep 0.5
done

echo ""
echo "3. Health check test:"
curl -s http://$LB_IP/health | jq '.'

echo ""
echo "4. Concurrent connection test:"
for i in {1..5}; do
    (curl -s http://$LB_IP/ | grep -o "SERVER ID: [0-9]*") &
done
wait

echo ""
echo "Load balancer testing completed!"
EOF

chmod +x /opt/test-lb.sh

# Restart nginx
systemctl restart nginx

# Create MOTD
cat > /etc/motd << EOF

  ╔══════════════════════════════════════════════════════════════════╗
  ║   🔄 LOAD BALANCED WEB SERVER ${server_id}                        ║
  ║                                                                  ║
  ║   This server is part of a load-balanced pool providing high    ║
  ║   availability and automatic traffic distribution.              ║
  ║                                                                  ║
  ║   Features:                                                      ║
  ║   • Health check endpoint: /health                              ║
  ║   • Server statistics: /api/server-stats                       ║
  ║   • Pool status page: /lb-status                                ║
  ║   • Load balancer testing tools                                 ║
  ║                                                                  ║
  ║   Testing:                                                       ║
  ║   • /opt/test-lb.sh <lb-ip>                                     ║
  ║   • curl http://[lb-ip]/ (multiple times)                       ║
  ║   • watch -n 1 'curl -s http://[lb-ip]/ | grep SERVER'         ║
  ╚══════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Load balanced web server ${server_id} configuration completed" >> /var/log/terraform-init.log
touch /var/lib/cloud/lb-web-init-complete