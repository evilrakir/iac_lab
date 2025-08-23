#!/bin/bash
# Database server user data script
# Configures MySQL and PostgreSQL database servers

# Set hostname
hostnamectl set-hostname "${hostname}"

# Update system
apt-get update

# Install database packages
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    git \
    nginx \
    mysql-server \
    postgresql \
    postgresql-contrib \
    python3 \
    python3-pip \
    redis-server \
    memcached

# Configure MySQL
systemctl enable mysql
systemctl start mysql

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'terraform123';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create application database and user
mysql -u root -pterraform123 -e "CREATE DATABASE IF NOT EXISTS webapp;"
mysql -u root -pterraform123 -e "CREATE USER IF NOT EXISTS 'webapp'@'%' IDENTIFIED BY 'webapp123';"
mysql -u root -pterraform123 -e "GRANT ALL PRIVILEGES ON webapp.* TO 'webapp'@'%';"
mysql -u root -pterraform123 -e "FLUSH PRIVILEGES;"

# Configure MySQL to accept remote connections
sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

# Configure PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# Set PostgreSQL password and create database
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'terraform123';"
sudo -u postgres createdb webapp
sudo -u postgres psql -c "CREATE USER webapp WITH PASSWORD 'webapp123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE webapp TO webapp;"

# Configure PostgreSQL to accept remote connections
PG_VERSION=$(pg_config --version | awk '{print $2}' | cut -d. -f1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"

echo "listen_addresses = '*'" >> $PG_CONFIG_DIR/postgresql.conf
echo "host all all 10.0.0.0/16 md5" >> $PG_CONFIG_DIR/pg_hba.conf

systemctl restart postgresql

# Configure Redis
systemctl enable redis-server
systemctl start redis-server

# Configure Redis to accept remote connections
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/# requirepass foobared/requirepass terraform123/' /etc/redis/redis.conf
systemctl restart redis-server

# Configure Memcached
systemctl enable memcached
systemctl start memcached

# Configure nginx for database monitoring dashboard
systemctl enable nginx
systemctl start nginx

# Create database monitoring dashboard
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Database Server ${server_id} - Backend Services</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #8e44ad 0%, #9b59b6 100%);
            color: white;
        }
        .container { 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 10px; 
            backdrop-filter: blur(10px);
        }
        .server-badge { 
            background: #27ae60; 
            padding: 10px 20px; 
            border-radius: 25px; 
            display: inline-block; 
            margin: 10px 0;
            font-weight: bold;
        }
        .status { color: #27ae60; }
        .info { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 5px; margin: 15px 0; }
        pre { background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; overflow-x: auto; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .service { padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; margin: 10px 0; }
        .service h4 { margin: 0 0 10px 0; color: #f39c12; }
        .metric { text-align: center; padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; }
        .metric h3 { margin: 0; color: #e74c3c; }
        .metric .value { font-size: 1.5em; margin: 10px 0; }
    </style>
    <script>
        function updateStatus() {
            fetch('/api/db-status')
                .then(response => response.json())
                .then(data => {
                    Object.keys(data.services).forEach(service => {
                        const elem = document.getElementById(service + '-status');
                        if (elem) {
                            elem.textContent = data.services[service] ? 'Running' : 'Stopped';
                            elem.style.color = data.services[service] ? '#27ae60' : '#e74c3c';
                        }
                    });
                    
                    document.getElementById('cpu-usage').textContent = data.cpu + '%';
                    document.getElementById('memory-usage').textContent = data.memory + '%';
                    document.getElementById('disk-usage').textContent = data.disk + '%';
                    document.getElementById('connections').textContent = data.connections;
                })
                .catch(() => console.log('Status update failed'));
        }
        
        setInterval(updateStatus, 5000);
        window.onload = updateStatus;
    </script>
</head>
<body>
    <div class="container">
        <h1>🗄️ Database Server ${server_id}</h1>
        <div class="server-badge">DB SERVER ID: ${server_id}</div>
        <p class="status">✅ Database services are running and ready</p>
        
        <div class="info">
            <h3>🏷️ Server Information</h3>
            <p><strong>Hostname:</strong> ${hostname}</p>
            <p><strong>Server ID:</strong> ${server_id}</p>
            <p><strong>Role:</strong> Backend Database Server</p>
            <p><strong>Network:</strong> Private (Database Subnet)</p>
        </div>
        
        <div class="grid">
            <div class="service">
                <h4>🐬 MySQL Database</h4>
                <p>Status: <span id="mysql-status" class="status">Checking...</span></p>
                <p>Port: 3306</p>
                <p>Database: webapp</p>
                <p>User: webapp</p>
            </div>
            
            <div class="service">
                <h4>🐘 PostgreSQL Database</h4>
                <p>Status: <span id="postgresql-status" class="status">Checking...</span></p>
                <p>Port: 5432</p>
                <p>Database: webapp</p>
                <p>User: webapp</p>
            </div>
            
            <div class="service">
                <h4>🔴 Redis Cache</h4>
                <p>Status: <span id="redis-status" class="status">Checking...</span></p>
                <p>Port: 6379</p>
                <p>Auth: Required</p>
                <p>Memory Cache: Available</p>
            </div>
            
            <div class="service">
                <h4>⚡ Memcached</h4>
                <p>Status: <span id="memcached-status" class="status">Checking...</span></p>
                <p>Port: 11211</p>
                <p>Memory Cache: 64MB</p>
                <p>Network: Local</p>
            </div>
        </div>
        
        <div class="grid">
            <div class="metric">
                <h3>CPU Usage</h3>
                <div class="value" id="cpu-usage">--</div>
            </div>
            <div class="metric">
                <h3>Memory Usage</h3>
                <div class="value" id="memory-usage">--</div>
            </div>
            <div class="metric">
                <h3>Disk Usage</h3>
                <div class="value" id="disk-usage">--</div>
            </div>
            <div class="metric">
                <h3>DB Connections</h3>
                <div class="value" id="connections">--</div>
            </div>
        </div>
        
        <div class="info">
            <h3>🔗 Connection Information</h3>
            <p><strong>MySQL:</strong> mysql -h ${hostname} -u webapp -p webapp</p>
            <p><strong>PostgreSQL:</strong> psql -h ${hostname} -U webapp -d webapp</p>
            <p><strong>Redis:</strong> redis-cli -h ${hostname} -a terraform123</p>
            <p><strong>SSH:</strong> Via bastion host only</p>
        </div>
        
        <div class="info">
            <h3>🛡️ Security Configuration</h3>
            <ul>
                <li>Access restricted to web subnet and bastion host</li>
                <li>Database authentication required</li>
                <li>SSH access via bastion host only</li>
                <li>Firewall rules configured for database ports</li>
            </ul>
        </div>
        
        <p><em>Generated by Database Server ${server_id} at $(date)</em></p>
    </div>
</body>
</html>
EOF

# Create database status API
mkdir -p /var/www/html/api

cat > /var/www/html/api/db-status << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Check service status
mysql_status=$(systemctl is-active mysql | grep -q "active" && echo "true" || echo "false")
postgresql_status=$(systemctl is-active postgresql | grep -q "active" && echo "true" || echo "false")
redis_status=$(systemctl is-active redis-server | grep -q "active" && echo "true" || echo "false")
memcached_status=$(systemctl is-active memcached | grep -q "active" && echo "true" || echo "false")

# Get system stats
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)

# Get database connections
mysql_connections=$(mysql -u root -pterraform123 -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}' || echo "0")

cat << END
{
  "services": {
    "mysql": $mysql_status,
    "postgresql": $postgresql_status,
    "redis": $redis_status,
    "memcached": $memcached_status
  },
  "cpu": "${cpu_usage:-0}",
  "memory": "${memory_usage:-0}",
  "disk": "${disk_usage:-0}",
  "connections": "${mysql_connections}",
  "server_id": "${server_id}",
  "timestamp": "$(date -Iseconds)"
}
END
EOF

chmod +x /var/www/html/api/db-status

# Configure nginx to serve API
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    # Add server identification header
    add_header X-Server-ID "${server_id}" always;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # API endpoints
    location ~ ^/(api/db-status)$ {
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

# Create sample data in databases
mysql -u root -pterraform123 webapp << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@example.com'),
    ('user1', 'user1@example.com'),
    ('user2', 'user2@example.com');

CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(32) PRIMARY KEY,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
EOF

sudo -u postgres psql webapp << 'EOF'
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price) VALUES 
    ('Product A', 29.99),
    ('Product B', 49.99),
    ('Product C', 19.99);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(id),
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Create database backup script
cat > /opt/backup-databases.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/databases"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup MySQL
mysqldump -u root -pterraform123 --all-databases > $BACKUP_DIR/mysql_backup_$DATE.sql

# Backup PostgreSQL
sudo -u postgres pg_dumpall > $BACKUP_DIR/postgresql_backup_$DATE.sql

# Cleanup old backups (keep 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "$(date): Database backup completed" >> /var/log/database-backup.log
EOF

chmod +x /opt/backup-databases.sh

# Set up daily backup cron job
echo "0 2 * * * /opt/backup-databases.sh" | crontab -

# Create database monitoring script
cat > /opt/db-monitor.sh << 'EOF'
#!/bin/bash
# Database monitoring script

while true; do
    # Check MySQL
    if ! systemctl is-active --quiet mysql; then
        echo "$(date): MySQL down, restarting..." >> /var/log/db-monitor.log
        systemctl restart mysql
    fi
    
    # Check PostgreSQL
    if ! systemctl is-active --quiet postgresql; then
        echo "$(date): PostgreSQL down, restarting..." >> /var/log/db-monitor.log
        systemctl restart postgresql
    fi
    
    # Check Redis
    if ! systemctl is-active --quiet redis-server; then
        echo "$(date): Redis down, restarting..." >> /var/log/db-monitor.log
        systemctl restart redis-server
    fi
    
    sleep 60
done
EOF

chmod +x /opt/db-monitor.sh

# Start monitoring in background
nohup /opt/db-monitor.sh > /dev/null 2>&1 &

# Restart services
systemctl restart nginx

# Create MOTD
cat > /etc/motd << EOF

  ╔══════════════════════════════════════════════════════════════════╗
  ║   🗄️  DATABASE SERVER ${server_id} - BACKEND SERVICES            ║
  ║                                                                  ║
  ║   Multi-database backend server with MySQL, PostgreSQL,         ║
  ║   Redis, and Memcached for comprehensive data services.         ║
  ║                                                                  ║
  ║   Services:                                                      ║
  ║   • MySQL Server (Port 3306)                                    ║
  ║   • PostgreSQL Server (Port 5432)                               ║
  ║   • Redis Cache (Port 6379)                                     ║
  ║   • Memcached (Port 11211)                                      ║
  ║   • Monitoring Dashboard (Port 80)                              ║
  ║                                                                  ║
  ║   Security:                                                      ║
  ║   • Access restricted to web subnet                             ║
  ║   • SSH via bastion host only                                   ║
  ║   • Database authentication required                            ║
  ║                                                                  ║
  ║   Management:                                                    ║
  ║   • Daily automated backups                                     ║
  ║   • Service monitoring and auto-restart                         ║
  ║   • Web dashboard: http://[server-ip]/                          ║
  ╚══════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Database server ${server_id} configuration completed" >> /var/log/terraform-init.log
touch /var/lib/cloud/db-init-complete