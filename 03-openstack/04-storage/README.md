# Exercise 4: Storage and Volumes

## Learning Objectives

In this exercise, you will:
- Create and manage OpenStack block storage volumes
- Attach volumes to virtual machines
- Configure different file systems (XFS, ext4)
- Implement storage performance testing and monitoring
- Set up automated backup strategies
- Create volume snapshots for disaster recovery
- Configure shared storage with NFS

## Prerequisites

- Completed Exercise 1 (OpenStack Provider Setup)
- SSH key pair available (terraform-key)
- Understanding of storage concepts (volumes, file systems, mounting)

## Architecture Overview

This exercise creates a comprehensive storage infrastructure:

```
Storage Server 1                    Storage Server 2
┌─────────────────┐                ┌─────────────────┐
│ OS Disk (Root)  │                │ OS Disk (Root)  │
│ Data Volume     │ 20GB XFS       │ Data Volume     │ 20GB XFS
│ Backup Volume   │ 50GB ext4      │ Backup Volume   │ 50GB ext4
│ Shared Volume   │ 40GB XFS/NFS   │                 │
└─────────────────┘                └─────────────────┘
         │                                   │
         └───────────── Network ─────────────┘
```

## What You'll Create

### Storage Infrastructure
- 💾 **Data Volumes** - High-performance XFS storage for applications
- 💿 **Backup Volumes** - Reliable ext4 storage for backups
- 🌐 **Shared Volume** - NFS-exported shared storage
- 📸 **Volume Snapshots** - Point-in-time backup copies

### Virtual Machines
- 🖥️ **Storage Servers** - Ubuntu instances with attached volumes
- ⚡ **Performance Tools** - FIO, Bonnie++, iostat monitoring
- 📊 **Web Dashboards** - Real-time storage monitoring

### Management Features
- 🔧 **Automated Mounting** - Persistent volume configuration
- 🔄 **Backup Automation** - Scheduled backup operations
- 📈 **Performance Testing** - Comprehensive benchmarking tools
- 🔍 **Health Monitoring** - Volume usage and I/O monitoring

## Quick Start

### 1. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy storage infrastructure
terraform apply
```

### 2. Access Storage Servers

```bash
# Get connection information
terraform output storage_servers_info

# Connect to storage server 1
ssh -i terraform-key ubuntu@<server-1-ip>

# View mounted volumes
lsblk
df -h
```

### 3. Test Storage Performance

```bash
# Run comprehensive benchmark
sudo /opt/storage-tools/benchmark.sh

# Test sequential read performance
sudo /opt/storage-tools/read-test.sh

# Test backup functionality
sudo /opt/storage-tools/backup-test.sh
```

## Understanding Storage Configuration

### Volume Creation and Attachment

```hcl
# Create data volume
resource "openstack_blockstorage_volume_v3" "data_volumes" {
  name        = "${var.project_name}-data-${count.index + 1}"
  size        = var.data_volume_size
  volume_type = "default"
}

# Attach to instance
resource "openstack_compute_volume_attach_v2" "data_volume_attachments" {
  instance_id = openstack_compute_instance_v2.storage_servers[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.data_volumes[count.index].id
  device      = "/dev/vdb"
}
```

### File System Configuration

The user-data script automatically:
1. **Formats volumes** with appropriate file systems
2. **Creates mount points** (/data, /backup, /shared)
3. **Updates /etc/fstab** for persistent mounting
4. **Sets permissions** for user access

### Volume Types and Use Cases

| Volume | File System | Purpose | Optimizations |
|--------|-------------|---------|---------------|
| Data | XFS | Application data | noatime, performance |
| Backup | ext4 | Backup storage | Reliability, compatibility |
| Shared | XFS + NFS | Distributed access | Network sharing |

## Storage Monitoring and Management

### Web Dashboard

Each storage server provides a web interface at `http://<server-ip>/`:
- 📊 **Real-time metrics** - CPU, memory, I/O wait
- 💾 **Volume usage** - Space utilization and availability
- 📈 **Performance data** - I/O statistics and throughput
- 🔧 **Management tools** - Links to storage utilities

### API Endpoints

- `http://<server-ip>/api/storage-status` - JSON storage metrics
- `http://<server-ip>/api/storage-info` - Detailed storage information

### Command-Line Tools

```bash
# Check volume status
lsblk
df -h
mount | grep -E "data|backup|shared"

# Monitor I/O performance
iostat -x 1
iotop

# Check volume health
sudo smartctl -a /dev/vdb
```

## Performance Testing

### Comprehensive Benchmarking

```bash
# Run full benchmark suite
sudo /opt/storage-tools/benchmark.sh
```

This tests:
- **Random 4K writes** - Database workload simulation
- **Sequential reads** - Large file transfer simulation
- **Multiple volumes** - Comparative performance analysis

### Custom Performance Tests

```bash
# Random write test (database simulation)
fio --name=db_simulation --directory=/data --size=1G --rw=randwrite --bs=4k --numjobs=4 --runtime=60s

# Sequential read test (file server simulation)
fio --name=file_server --directory=/data --size=2G --rw=read --bs=1M --numjobs=1 --runtime=60s

# Mixed workload test
fio --name=mixed --directory=/data --size=1G --rw=randrw --rwmixread=70 --bs=4k --numjobs=2 --runtime=60s
```

## Backup and Disaster Recovery

### Automated Backups

```bash
# Manual backup test
sudo /opt/storage-tools/backup-test.sh

# View backup schedule
crontab -l

# Check backup logs
sudo tail -f /var/log/auto-backup.log
```

### Volume Snapshots

Terraform creates volume snapshots automatically:

```bash
# View snapshot information
terraform output snapshots_info

# Create manual snapshot (via OpenStack CLI)
openstack volume snapshot create --volume <volume-id> manual-snapshot-$(date +%Y%m%d)
```

### Disaster Recovery Testing

```bash
# Simulate data loss
sudo rm /data/test-1gb.dat

# Restore from backup
cd /backup
sudo tar -xzf data-backup-<timestamp>.tar.gz -C /data
```

## Shared Storage with NFS

Storage Server 1 exports a shared volume via NFS:

### On Storage Server 1 (NFS Server)
```bash
# Check NFS exports
sudo exportfs -v

# View shared volume
ls -la /shared/

# Create shared data
echo "Shared data from server 1" | sudo tee /shared/test-file.txt
```

### On Storage Server 2 (NFS Client)
```bash
# Mount shared volume
sudo mkdir -p /mnt/shared
sudo mount -t nfs <server-1-ip>:/shared /mnt/shared

# Access shared data
cat /mnt/shared/test-file.txt

# Create data from client
echo "Data from server 2" | sudo tee /mnt/shared/client-file.txt
```

## Advanced Storage Features

### Logical Volume Management (LVM)

For advanced scenarios, you can configure LVM:

```bash
# Create physical volume
sudo pvcreate /dev/vdb

# Create volume group
sudo vgcreate data_vg /dev/vdb

# Create logical volumes
sudo lvcreate -L 10G -n app_data data_vg
sudo lvcreate -L 8G -n log_data data_vg

# Format and mount
sudo mkfs.xfs /dev/data_vg/app_data
sudo mkdir -p /data/apps
sudo mount /dev/data_vg/app_data /data/apps
```

### Volume Encryption

For sensitive data, implement encryption:

```bash
# Create encrypted volume
sudo cryptsetup luksFormat /dev/vdb

# Open encrypted volume
sudo cryptsetup luksOpen /dev/vdb encrypted_data

# Format and mount
sudo mkfs.xfs /dev/mapper/encrypted_data
sudo mount /dev/mapper/encrypted_data /data/secure
```

## Customization Options

### Adjustable Variables

```hcl
# Number of storage servers
storage_servers_count = 3

# Volume sizes
data_volume_size = 50    # GB
backup_volume_size = 100 # GB

# Project naming
project_name = "my-storage-lab"
```

### Scaling Storage

```bash
# Add more storage servers
terraform apply -var="storage_servers_count=3"

# Increase volume sizes
terraform apply -var="data_volume_size=50" -var="backup_volume_size=100"
```

## Common Storage Scenarios

### Database Storage
```bash
# Optimize for database workloads
sudo mount -o remount,noatime,nobarrier /data
```

### File Server Storage
```bash
# Configure for large file operations
echo 'vm.dirty_ratio = 5' | sudo tee -a /etc/sysctl.conf
echo 'vm.dirty_background_ratio = 2' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Archive Storage
```bash
# Set up compression for backup volume
sudo mount -o remount,compress=lzo /backup
```

## Troubleshooting

### Volume Not Mounting
```bash
# Check if volume is attached
lsblk

# Verify device exists
ls -la /dev/vdb

# Check file system
sudo fsck -f /dev/vdb

# Manual mount
sudo mount /dev/vdb /data
```

### Performance Issues
```bash
# Check I/O wait
iostat -x 1

# Monitor disk activity
sudo iotop -o

# Test volume performance
sudo hdparm -tT /dev/vdb
```

### NFS Issues
```bash
# Check NFS service
sudo systemctl status nfs-kernel-server

# Verify exports
sudo exportfs -v

# Test NFS connectivity
showmount -e <server-ip>
```

## PowerShell Storage Comparison

This OpenStack storage setup is similar to PowerShell storage management:

```powershell
# Create virtual disk (similar to OpenStack volume)
New-VHD -Path "C:\VMs\DataDisk.vhdx" -SizeBytes 20GB

# Attach to VM
Add-VMHardDiskDrive -VMName "StorageVM" -Path "C:\VMs\DataDisk.vhdx"

# Format and mount (inside VM)
Initialize-Disk -Number 1
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter E -FileSystem NTFS

# Storage monitoring
Get-Counter "\PhysicalDisk(*)\Disk Bytes/sec"
Get-Volume | Select-Object DriveLetter, Size, SizeRemaining
```

## Next Steps

After completing this exercise:
1. ✅ You understand OpenStack block storage concepts
2. ✅ You can create and manage volumes
3. ✅ You know how to configure file systems for different use cases
4. ✅ You can implement storage monitoring and alerting
5. ✅ You understand backup and disaster recovery strategies

Move on to **Exercise 5: Load Balancers and High Availability** to learn about distributing traffic!

## Cleanup

To remove all resources:

```bash
terraform destroy
```

This will remove:
- All storage servers and volumes
- Volume attachments and snapshots
- Floating IPs and security groups
- NFS exports and mount points

**Note**: Volume snapshots may need manual deletion if they have dependencies.