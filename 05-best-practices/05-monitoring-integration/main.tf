# ╔════════════════════════════════════════════════════════════════════╗
# ║  MONITORING AND OBSERVABILITY INTEGRATION                       ║
# ║  Deploy monitoring infrastructure with Terraform                ║
# ╚════════════════════════════════════════════════════════════════════╝

# Infrastructure without monitoring is flying blind. This exercise
# demonstrates how to provision monitoring, alerting, and dashboards
# as code alongside your infrastructure.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell scripts configuring Windows Performance Counters
# and Event Log monitoring - but for cloud-native observability:
#   PS: New-AzMetricAlertRuleV2 -Name "HighCPU" -TargetResourceId ...
#   TF: resource "aws_cloudwatch_metric_alarm" "high_cpu" { ... }

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# VARIABLES
# ========================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "alert_email" {
  description = "Email for alert notifications"
  type        = string
  default     = "ops-team@example.com"
}

variable "alert_thresholds" {
  description = "Monitoring alert thresholds"
  type = object({
    cpu_percent    = number
    memory_percent = number
    disk_percent   = number
    error_rate     = number
    response_time_ms = number
  })
  default = {
    cpu_percent      = 80
    memory_percent   = 85
    disk_percent     = 90
    error_rate       = 5
    response_time_ms = 2000
  }
}

# ========================================================================
# SECTION 1: CLOUDWATCH MONITORING (AWS)
# ========================================================================

resource "local_file" "cloudwatch_config" {
  filename = "./terraform-lab-output/monitoring/aws-cloudwatch.tf"
  content  = <<-EOT
    # ============================================
    # AWS CLOUDWATCH MONITORING AS CODE
    # ============================================

    # --- SNS Topic for Alerts ---
    resource "aws_sns_topic" "alerts" {
      name = "${var.project_name}-${var.environment}-alerts"
    }

    resource "aws_sns_topic_subscription" "email" {
      topic_arn = aws_sns_topic.alerts.arn
      protocol  = "email"
      endpoint  = "${var.alert_email}"
    }

    # --- CPU Alarm ---
    resource "aws_cloudwatch_metric_alarm" "high_cpu" {
      alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 3
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300  # 5 minutes
      statistic           = "Average"
      threshold           = ${var.alert_thresholds.cpu_percent}
      alarm_description   = "CPU utilization above ${var.alert_thresholds.cpu_percent}%"
      alarm_actions       = [aws_sns_topic.alerts.arn]
      ok_actions          = [aws_sns_topic.alerts.arn]

      dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.app.name
      }
    }

    # --- Error Rate Alarm ---
    resource "aws_cloudwatch_metric_alarm" "high_errors" {
      alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "5XXError"
      namespace           = "AWS/ApplicationELB"
      period              = 60
      statistic           = "Sum"
      threshold           = ${var.alert_thresholds.error_rate}
      alarm_description   = "5XX errors exceed ${var.alert_thresholds.error_rate}/min"
      alarm_actions       = [aws_sns_topic.alerts.arn]
    }

    # --- Dashboard ---
    resource "aws_cloudwatch_dashboard" "main" {
      dashboard_name = "${var.project_name}-${var.environment}"
      dashboard_body = jsonencode({
        widgets = [
          {
            type   = "metric"
            x      = 0
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "$${var.project_name}-asg"]
              ]
              period = 300
              stat   = "Average"
              title  = "CPU Utilization"
            }
          },
          {
            type   = "metric"
            x      = 12
            y      = 0
            width  = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "$${var.project_name}-alb"]
              ]
              period = 60
              stat   = "Sum"
              title  = "Request Count"
            }
          }
        ]
      })
    }
  EOT
}

# ========================================================================
# SECTION 2: MONITORING PATTERNS REFERENCE
# ========================================================================

resource "local_file" "monitoring_patterns" {
  filename = "./terraform-lab-output/monitoring/monitoring-patterns.json"
  content = jsonencode({
    title = "Infrastructure Monitoring Patterns"
    alert_thresholds = var.alert_thresholds
    patterns = {
      metrics = {
        description = "Numeric measurements over time"
        examples    = ["CPU %", "Memory %", "Request count", "Error rate"]
        terraform   = "aws_cloudwatch_metric_alarm, azurerm_monitor_metric_alert"
      }
      logs = {
        description = "Text-based event records"
        examples    = ["Application logs", "Access logs", "Audit logs"]
        terraform   = "aws_cloudwatch_log_group, azurerm_log_analytics_workspace"
      }
      traces = {
        description = "Request flow through distributed systems"
        examples    = ["API call chains", "Database queries", "External service calls"]
        terraform   = "aws_xray_sampling_rule, azurerm_application_insights"
      }
      dashboards = {
        description = "Visual display of metrics and status"
        examples    = ["CloudWatch dashboard", "Grafana dashboard", "Datadog dashboard"]
        terraform   = "aws_cloudwatch_dashboard, grafana_dashboard"
      }
    }
    golden_signals = {
      description = "Google SRE's four golden signals for monitoring"
      signals = {
        latency    = "How long requests take (p50, p95, p99)"
        traffic    = "How much demand is being placed on the system"
        errors     = "Rate of failed requests"
        saturation = "How full the system is (CPU, memory, disk)"
      }
    }
  })
}

# ========================================================================
# SECTION 3: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-monitoring.ps1"
  content  = <<-EOT
    # Monitoring: Terraform vs PowerShell Approaches
    # ================================================

    # TERRAFORM                        | POWERSHELL
    # ---------------------------------|-------------------------------
    # cloudwatch_metric_alarm          | New-AzMetricAlertRuleV2
    # cloudwatch_dashboard             | New-AzDashboard
    # cloudwatch_log_group             | New-AzOperationalInsightsWorkspace
    # sns_topic (alerts)               | New-AzActionGroup
    # Monitoring as code (versioned)   | Scripts run ad-hoc

    # PowerShell: Setting up monitoring

    # Create Azure metric alert
    # $$condition = New-AzMetricAlertRuleV2Criteria `
    #   -MetricName "Percentage CPU" `
    #   -TimeAggregation Average `
    #   -Operator GreaterThan `
    #   -Threshold ${var.alert_thresholds.cpu_percent}

    # Add-AzMetricAlertRuleV2 `
    #   -Name "HighCPU" `
    #   -ResourceGroupName "myapp-rg" `
    #   -TargetResourceId $$vmId `
    #   -Condition $$condition `
    #   -ActionGroupId $$actionGroupId

    # Windows Performance Monitoring
    # Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 10

    # Windows Event Log Monitoring
    # Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2} -MaxEvents 10

    Write-Host "Monitoring Comparison:" -ForegroundColor Yellow
    Write-Host "  Terraform: Monitoring provisioned WITH infrastructure"
    Write-Host "  PowerShell: Monitoring configured AFTER deployment"
    Write-Host ""
    Write-Host "  Terraform advantage: Monitoring is version-controlled"
    Write-Host "  PowerShell advantage: Can query live metrics interactively"
    Write-Host "  Best practice: Use Terraform for setup, PowerShell for investigation"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "monitoring_config" {
  description = "Current monitoring configuration"
  value = {
    project     = var.project_name
    environment = var.environment
    thresholds  = var.alert_thresholds
    alert_email = var.alert_email
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    monitoring_as_code = "Provision monitoring alongside infrastructure for consistency"
    golden_signals     = "Monitor latency, traffic, errors, and saturation"
    alerting           = "Set thresholds per environment (tighter for production)"
    dashboards         = "Create dashboards as code for reproducible observability"
    log_management     = "Set retention policies to control log storage costs"
    multi_cloud        = "Same patterns work across AWS CloudWatch, Azure Monitor, GCP Cloud Monitoring"
  }
}
