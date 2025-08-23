#!/bin/bash
# Storage server user data script
# Configures storage services, file systems, and monitoring

# Set hostname
hostnamectl set-hostname "${hostname}"

# Update system
apt-get update

# Install storage and monitoring packages
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    iotop \
    git \
    nginx \
    python3 \
    python3-pip \
    lvm2 \
    xfsprogs \
    ext4-utils \
    nfs-kernel-server \
    nfs-common \
    open-iscsi \
    targetcli-fb \
    multipath-tools \
    smartmontools \
    fio \
    bonnie++ \
    sysstat \
    prometheus-node-exporter

# Configure nginx
systemctl enable nginx
systemctl start nginx

# Wait for volumes to be attached
echo "Waiting for volumes to be attached..."
sleep 30

# Function to wait for device
wait_for_device() {
    local device=$1
    local timeout=60
    local count=0
    
    while [ ! -b "$device" ] && [ $count -lt $timeout ]; do
        echo "Waiting for device $device... ($count/$timeout)"
        sleep 1
        count=$((count + 1))
    done
    
    if [ ! -b "$device" ]; then
        echo "ERROR: Device $device not found after $timeout seconds"
        return 1
    fi
    
    echo "Device $device is available"
    return 0
}

# Wait for all expected devices
wait_for_device /dev/vdb  # Data volume
wait_for_device /dev/vdc  # Backup volume

# Check if shared volume is attached (only on server 1)
if [ "${server_id}" = "1" ]; then
    wait_for_device /dev/vdd  # Shared volume
fi

# Create file systems on the volumes
echo "Creating file systems..."

# Data volume (/dev/vdb) - XFS for performance
if [ -b /dev/vdb ]; then
    echo "Formatting data volume (/dev/vdb) with XFS..."
    mkfs.xfs /dev/vdb
    
    # Create mount point and mount
    mkdir -p /data
    mount /dev/vdb /data
    
    # Add to fstab for persistent mounting
    echo "/dev/vdb /data xfs defaults,noatime 0 2" >> /etc/fstab
    
    # Set permissions
    chown ubuntu:ubuntu /data
    chmod 755 /data
    
    echo "Data volume mounted at /data"
fi

# Backup volume (/dev/vdc) - ext4 for compatibility
if [ -b /dev/vdc ]; then
    echo "Formatting backup volume (/dev/vdc) with ext4..."
    mkfs.ext4 /dev/vdc
    
    # Create mount point and mount
    mkdir -p /backup
    mount /dev/vdc /backup
    
    # Add to fstab
    echo "/dev/vdc /backup ext4 defaults 0 2" >> /etc/fstab
    
    # Set permissions
    chown ubuntu:ubuntu /backup
    chmod 755 /backup
    
    echo "Backup volume mounted at /backup"
fi

# Shared volume (/dev/vdd) - only on server 1
if [ "${server_id}" = "1" ] && [ -b /dev/vdd ]; then
    echo "Formatting shared volume (/dev/vdd) with XFS..."
    mkfs.xfs /dev/vdd
    
    # Create mount point and mount
    mkdir -p /shared
    mount /dev/vdd /shared
    
    # Add to fstab
    echo "/dev/vdd /shared xfs defaults,noatime 0 2" >> /etc/fstab
    
    # Set permissions for sharing
    chown ubuntu:ubuntu /shared
    chmod 755 /shared
    
    # Configure NFS export for shared volume
    echo "/shared *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -a
    systemctl enable nfs-kernel-server
    systemctl start nfs-kernel-server
    
    echo "Shared volume mounted at /shared and exported via NFS"
fi

# Create test data and directory structure
mkdir -p /data/applications /data/databases /data/logs /data/temp
mkdir -p /backup/daily /backup/weekly /backup/monthly

# Create sample data for testing
echo "Creating sample data for testing..."
dd if=/dev/zero of=/data/test-1gb.dat bs=1M count=1024 2>/dev/null
dd if=/dev/zero of=/data/temp/test-100mb.dat bs=1M count=100 2>/dev/null

# Create storage monitoring dashboard
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Storage Server ${server_id} - Volume Management</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: linear-gradient(135deg, #2980b9 0%, #3498db 100%);
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
        .volume { padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; margin: 10px 0; }
        .volume h4 { margin: 0 0 10px 0; color: #f39c12; }
        .metric { text-align: center; padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px; }
        .metric h3 { margin: 0; color: #e67e22; }
        .metric .value { font-size: 1.5em; margin: 10px 0; }
        .progress { background: rgba(0,0,0,0.3); border-radius: 10px; overflow: hidden; height: 20px; margin: 5px 0; }
        .progress-bar { height: 100%; background: linear-gradient(45deg, #27ae60, #2ecc71); transition: width 0.3s; }
    </style>
    <script>
        function updateStorage() {
            fetch('/api/storage-status')
                .then(response => response.json())
                .then(data => {
                    // Update volume information
                    if (data.volumes) {
                        Object.keys(data.volumes).forEach(volume => {
                            const info = data.volumes[volume];
                            const usedElem = document.getElementById(volume + '-used');
                            const availElem = document.getElementById(volume + '-avail');
                            const progressElem = document.getElementById(volume + '-progress');
                            
                            if (usedElem && info.used) usedElem.textContent = info.used;
                            if (availElem && info.available) availElem.textContent = info.available;
                            if (progressElem && info.use_percent) {
                                progressElem.style.width = info.use_percent;
                            }
                        });
                    }
                    
                    // Update system metrics
                    if (data.system) {
                        const sys = data.system;
                        document.getElementById('cpu-usage').textContent = sys.cpu + '%';
                        document.getElementById('memory-usage').textContent = sys.memory + '%';
                        document.getElementById('load-avg').textContent = sys.load;
                        document.getElementById('io-wait').textContent = sys.iowait + '%';
                    }
                })
                .catch(() => console.log('Storage status update failed'));
        }
        
        setInterval(updateStorage, 5000);
        window.onload = updateStorage;
    </script>
</head>
<body>
    <div class="container">
        <h1>💾 Storage Server ${server_id}</h1>
        <div class="server-badge">STORAGE SERVER ID: ${server_id}</div>
        <p class="status">✅ Storage volumes are mounted and ready</p>
        
        <div class="info">
            <h3>🏷️ Server Information</h3>
            <p><strong>Hostname:</strong> ${hostname}</p>
            <p><strong>Server ID:</strong> ${server_id}</p>
            <p><strong>Role:</strong> Storage and Volume Management</p>
            <p><strong>File Systems:</strong> XFS (data), ext4 (backup)</p>
        </div>
        
        <div class="grid">
            <div class="volume">
                <h4>📁 Data Volume (/data)</h4>
                <p>Filesystem: XFS</p>
                <p>Used: <span id="data-used">--</span></p>
                <p>Available: <span id="data-avail">--</span></p>
                <div class="progress">
                    <div class="progress-bar" id="data-progress" style="width: 0%"></div>
                </div>
            </div>
            
            <div class="volume">
                <h4>💿 Backup Volume (/backup)</h4>
                <p>Filesystem: ext4</p>
                <p>Used: <span id="backup-used">--</span></p>
                <p>Available: <span id="backup-avail">--</span></p>
                <div class="progress">
                    <div class="progress-bar" id="backup-progress" style="width: 0%"></div>
                </div>
            </div>
        </div>
        
        $(if [ "${server_id}" = "1" ]; then echo '
        <div class="volume">
            <h4>🌐 Shared Volume (/shared)</h4>
            <p>Filesystem: XFS</p>
            <p>NFS Export: Active</p>
            <p>Used: <span id="shared-used">--</span></p>
            <p>Available: <span id="shared-avail">--</span></p>
            <div class="progress">
                <div class="progress-bar" id="shared-progress" style="width: 0%"></div>
            </div>
        </div>'; fi)
        
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
                <h3>Load Average</h3>
                <div class="value" id="load-avg">--</div>
            </div>
            <div class="metric">
                <h3>I/O Wait</h3>
                <div class="value" id="io-wait">--</div>
            </div>
        </div>
        
        <div class="info">
            <h3>📊 Performance Testing</h3>
            <p>Random Write Test: <code>/opt/storage-tools/benchmark.sh</code></p>
            <p>Sequential Read Test: <code>/opt/storage-tools/read-test.sh</code></p>
            <p>Volume Backup Test: <code>/opt/storage-tools/backup-test.sh</code></p>
        </div>
        
        <div class="info">
            <h3>🔧 Management Tools</h3>
            <pre id="storage-info">Loading storage information...</pre>
        </div>
        
        <p><em>Generated by Storage Server ${server_id} at $(date)</em></p>
    </div>
    
    <script>
        fetch('/api/storage-info')
            .then(response => response.text())
            .then(data => document.getElementById('storage-info').textContent = data)
            .catch(() => document.getElementById('storage-info').textContent = 'Storage info not available');
    </script>
</body>
</html>
EOF

# Create storage status API
mkdir -p /var/www/html/api

cat > /var/www/html/api/storage-status << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Get volume information
get_volume_info() {
    local mount_point=$1
    if mountpoint -q "$mount_point"; then
        df -h "$mount_point" | tail -1 | awk '{
            print "\"used\": \"" $3 "\", \"available\": \"" $4 "\", \"use_percent\": \"" $5 "\""
        }'
    else
        echo "\"used\": \"N/A\", \"available\": \"N/A\", \"use_percent\": \"0%\""
    fi
}

# Get system stats
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
load_avg=$(cat /proc/loadavg | cut -d' ' -f1)
iowait=$(iostat 1 2 | tail -1 | awk '{print $4}')

cat << END
{
  "volumes": {
    "data": { $(get_volume_info /data) },
    "backup": { $(get_volume_info /backup) }$([ -d /shared ] && echo ', "shared": {' $(get_volume_info /shared) '}')
  },
  "system": {
    "cpu": "${cpu_usage:-0}",
    "memory": "${memory_usage:-0}",
    "load": "${load_avg}",
    "iowait": "${iowait:-0}"
  },
  "server_id": "${server_id}",
  "timestamp": "$(date -Iseconds)"
}
END
EOF

chmod +x /var/www/html/api/storage-status

# Create storage info API
cat > /var/www/html/api/storage-info << 'EOF'
#!/bin/bash
echo "Content-Type: text/plain"
echo ""

echo "=== STORAGE INFORMATION ==="
echo "Block Devices:"
lsblk | sed 's/^/  /'
echo ""
echo "Mount Points:"
df -h | grep -E "^/dev" | sed 's/^/  /'
echo ""
echo "File System Details:"
mount | grep -E "^/dev" | sed 's/^/  /'
echo ""
echo "I/O Statistics:"
iostat -x 1 1 | tail -n +4 | sed 's/^/  /'
EOF

chmod +x /var/www/html/api/storage-info

# Configure nginx to serve APIs
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
    location ~ ^/(api/storage-status|api/storage-info)$ {
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

# Create storage management tools
mkdir -p /opt/storage-tools

# Benchmark script
cat > /opt/storage-tools/benchmark.sh << 'EOF'
#!/bin/bash
echo "=== STORAGE PERFORMANCE BENCHMARK ==="
echo "Starting comprehensive storage tests..."

# Test data volume performance
if [ -d /data ]; then
    echo ""
    echo "Testing /data volume (XFS):"
    echo "Random 4K write test (30 seconds):"
    fio --name=random_write --directory=/data --size=1G --rw=randwrite --bs=4k --numjobs=4 --time_based --runtime=30s --group_reporting --ioengine=libaio --direct=1 --iodepth=32
    
    echo ""
    echo "Sequential read test:"
    fio --name=sequential_read --directory=/data --size=1G --rw=read --bs=1M --numjobs=1 --time_based --runtime=30s --group_reporting --ioengine=libaio --direct=1
fi

# Test backup volume performance
if [ -d /backup ]; then
    echo ""
    echo "Testing /backup volume (ext4):"
    echo "Random 4K write test (30 seconds):"
    fio --name=backup_test --directory=/backup --size=500M --rw=randwrite --bs=4k --numjobs=1 --time_based --runtime=30s --group_reporting --ioengine=libaio --direct=1
fi

echo ""
echo "Benchmark completed!"
EOF

chmod +x /opt/storage-tools/benchmark.sh

# Read test script
cat > /opt/storage-tools/read-test.sh << 'EOF'
#!/bin/bash
echo "=== SEQUENTIAL READ PERFORMANCE TEST ==="

for volume in /data /backup; do
    if [ -d "$volume" ]; then
        echo "Testing $volume:"
        echo "  Creating test file..."
        dd if=/dev/zero of="$volume/test-read.dat" bs=1M count=512 2>/dev/null
        
        echo "  Sequential read test:"
        time dd if="$volume/test-read.dat" of=/dev/null bs=1M 2>&1 | grep -E "(copied|MB/s)"
        
        echo "  Cleaning up..."
        rm -f "$volume/test-read.dat"
        echo ""
    fi
done
EOF

chmod +x /opt/storage-tools/read-test.sh

# Backup test script
cat > /opt/storage-tools/backup-test.sh << 'EOF'
#!/bin/bash
echo "=== BACKUP VOLUME TEST ==="

# Create test data in data volume
echo "Creating test data in /data..."
mkdir -p /data/test-backup
for i in {1..10}; do
    dd if=/dev/urandom of="/data/test-backup/file$i.dat" bs=1M count=10 2>/dev/null
done

# Backup to backup volume
echo "Backing up to /backup volume..."
time tar -czf /backup/test-backup-$(date +%Y%m%d_%H%M%S).tar.gz -C /data test-backup

# Verify backup
echo "Verifying backup integrity..."
cd /backup
latest_backup=$(ls -t test-backup-*.tar.gz | head -1)
tar -tzf "$latest_backup" > /dev/null && echo "Backup verified successfully" || echo "Backup verification failed"

# Show backup size
echo "Backup details:"
ls -lh test-backup-*.tar.gz | tail -5

echo "Backup test completed!"
EOF

chmod +x /opt/storage-tools/backup-test.sh

# Volume monitoring script
cat > /opt/storage-tools/volume-monitor.sh << 'EOF'
#!/bin/bash
# Volume monitoring and alerting script

while true; do
    # Check volume usage
    for volume in /data /backup /shared; do
        if mountpoint -q "$volume" 2>/dev/null; then
            usage=$(df "$volume" | tail -1 | awk '{print $5}' | cut -d'%' -f1)
            if [ "$usage" -gt 90 ]; then
                echo "$(date): WARNING: $volume is ${usage}% full" >> /var/log/volume-monitor.log
            fi
        fi
    done
    
    # Check for I/O errors
    dmesg | tail -50 | grep -i "i/o error" && echo "$(date): I/O errors detected" >> /var/log/volume-monitor.log
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/storage-tools/volume-monitor.sh

# Start volume monitoring in background
nohup /opt/storage-tools/volume-monitor.sh > /dev/null 2>&1 &

# Create automated backup script
cat > /opt/storage-tools/auto-backup.sh << 'EOF'
#!/bin/bash
# Automated backup script

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/auto-backup.log"

echo "$(date): Starting automated backup" >> $LOG_FILE

# Backup data volume contents
if [ -d /data ] && [ -d /backup ]; then
    tar -czf "/backup/data-backup-$BACKUP_DATE.tar.gz" -C /data . 2>>$LOG_FILE
    
    if [ $? -eq 0 ]; then
        echo "$(date): Data backup completed successfully" >> $LOG_FILE
    else
        echo "$(date): Data backup failed" >> $LOG_FILE
    fi
    
    # Clean up old backups (keep 7 days)
    find /backup -name "data-backup-*.tar.gz" -mtime +7 -delete
fi

echo "$(date): Automated backup finished" >> $LOG_FILE
EOF

chmod +x /opt/storage-tools/auto-backup.sh

# Set up daily backup cron job
echo "0 3 * * * /opt/storage-tools/auto-backup.sh" | crontab -

# Configure SMART monitoring for disk health
smartctl --scan >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "SMART monitoring available"
    # Enable SMART monitoring for all devices
    for device in /dev/vdb /dev/vdc /dev/vdd; do
        if [ -b "$device" ]; then
            smartctl -s on "$device" 2>/dev/null
        fi
    done
fi

# Restart services
systemctl restart nginx

# Create MOTD
cat > /etc/motd << EOF

  ╔══════════════════════════════════════════════════════════════════╗
  ║   💾 STORAGE SERVER ${server_id} - VOLUME MANAGEMENT              ║
  ║                                                                  ║
  ║   Multi-volume storage server with XFS and ext4 file systems    ║
  ║   and comprehensive monitoring and backup capabilities.          ║
  ║                                                                  ║
  ║   Mounted Volumes:                                               ║
  ║   • /data - XFS data volume (${data_volume_size}GB)                             ║
  ║   • /backup - ext4 backup volume (${backup_volume_size}GB)                      ║$([ "${server_id}" = "1" ] && echo "   ║   • /shared - XFS shared volume via NFS                         ║")
  ║                                                                  ║
  ║   Management Tools:                                              ║
  ║   • /opt/storage-tools/benchmark.sh                             ║
  ║   • /opt/storage-tools/backup-test.sh                           ║
  ║   • /opt/storage-tools/volume-monitor.sh                        ║
  ║                                                                  ║
  ║   Monitoring:                                                    ║
  ║   • Web dashboard: http://[server-ip]/                          ║
  ║   • Storage API: http://[server-ip]/api/storage-status          ║
  ║   • Automated backups: Daily at 3 AM                           ║
  ╚══════════════════════════════════════════════════════════════════╝

EOF

# Log completion
echo "$(date): Storage server ${server_id} configuration completed" >> /var/log/terraform-init.log
touch /var/lib/cloud/storage-init-complete