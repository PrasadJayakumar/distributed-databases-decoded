#Requires -Version 5.0

<#
.SYNOPSIS
    Comprehensive Cassandra cluster status checker

.DESCRIPTION
    This script provides a detailed status check of a multi-node Cassandra cluster
    running in containers. It checks container health, cluster ring status, and
    resource usage.

.PARAMETER ShowLogs
    Show recent logs for unhealthy nodes

.PARAMETER Detailed
    Show additional detailed information about the cluster

.EXAMPLE
    .\check-cluster-status.ps1
    .\check-cluster-status.ps1 -ShowLogs

.NOTES
    Requires Podman and Docker Compose to be installed and accessible
#>

[CmdletBinding()]
param(
    [switch]$ShowLogs
)

# Script configuration
$script:NodeNames = @("cassandra-node1", "cassandra-node2", "cassandra-node3", "cassandra-node4")

#region Helper Functions

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Yellow
}

function Write-StatusMessage {
    param(
        [string]$Message,
        [string]$Status,
        [string]$NodeName = ""
    )
    
    $color = switch ($Status.ToLower()) {
        "healthy" { "Green" }
        "unhealthy" { "Red" }
        "starting" { "Yellow" }
        "error" { "Red" }
        default { "White" }
    }
    
    $displayMessage = if ($NodeName) { "${NodeName}: $Message" } else { $Message }
    Write-Host $displayMessage -ForegroundColor $color
}

function Test-CommandExists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

function Get-NodeHealth {
    param([string]$NodeName)
    
    try {
        # Always check if container is running first
        $status = podman inspect --format='{{.State.Status}}' $NodeName 2>$null
        if ($status -ne 'running') {
            if ($status) {
                return $status
            } else {
                return 'not-running'
            }
        }
        # If running, check health status if available
        $hasHealth = podman inspect --format='{{json .State.Health}}' $NodeName 2>$null | ConvertFrom-Json
        if ($hasHealth -and $hasHealth.Status) {
            return $hasHealth.Status
        } else {
            return 'running'
        }
    }
    catch {
        return "error"
    }
}

function Get-HealthyNode {
    param([hashtable]$NodeHealthStatus)
    
    foreach ($node in $script:NodeNames) {
        if ($NodeHealthStatus[$node] -eq "healthy") {
            return $node
        }
    }
    return $null
}

function Invoke-CassandraCommand {
    param(
        [string]$NodeName,
        [string]$Command,
        [string]$Description
    )
    
    try {
        $result = Invoke-Expression "podman exec $NodeName $Command 2>`$null"
        if ($result) {
            Write-Host $result
            return $true
        } else {
            Write-StatusMessage "Unable to get $Description from $NodeName" "error"
            return $false
        }
    }
    catch {
        Write-StatusMessage "Error executing $Description on $NodeName`: $($_.Exception.Message)" "error"
        return $false
    }
}

#endregion

function Test-Prerequisites {
    Write-SectionHeader "Prerequisites Check"
    
    $missingTools = @()
    
    if (-not (Test-CommandExists "podman")) {
        $missingTools += "podman"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-StatusMessage "Missing required tools: $($missingTools -join ', ')" "error"
        return $false
    }
    
    Write-StatusMessage "All required tools are available" "healthy"
    return $true
}

function Get-NodesHealthStatus {
    Write-SectionHeader "Container Health Status"
    
    $healthStatus = @{}
    
    $ipMap = @{}
    foreach ($node in $script:NodeNames) {
        $health = Get-NodeHealth -NodeName $node
        $healthStatus[$node] = $health

        # Get container IP address
        $ip = podman inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $node 2>$null
        $ipMap[$node] = $ip

        # Always check container status first
        $status = podman inspect --format='{{.State.Status}}' $node 2>$null
        if ($status -ne 'running') {
            if ($status) {
                $message = "Container status: $status"
            } else {
                $message = "Not running"
            }
        } else {
            # If running, check health status if available
            $healthJson = podman inspect --format='{{json .State.Health}}' $node 2>$null | ConvertFrom-Json
            if ($healthJson -and $healthJson.Status) {
                $message = "Health check: $($healthJson.Status)"
            } else {
                $message = "Container running (no health check)"
            }
        }
        # Tag message with IP
        $taggedNode = if ($ip) { "$node ($ip)" } else { $node }
        Write-StatusMessage $message $health $taggedNode

        if ($ShowLogs -and $health -ne "healthy") {
            Write-Host "  Recent logs:" -ForegroundColor Gray
            podman logs --tail 10 $node 2>$null | ForEach-Object {
                Write-Host "    $_" -ForegroundColor Gray
            }
        }
    }

    return $healthStatus
}

function Get-ClusterStatus {
    param([hashtable]$NodeHealthStatus)
    $healthyNode = Get-HealthyNode -NodeHealthStatus $NodeHealthStatus
    if (-not $healthyNode) {
        Write-StatusMessage "Cannot check cluster status - no healthy nodes found" "error"
        return
    }

    Write-SectionHeader "Cluster Information"
    Invoke-CassandraCommand -NodeName $healthyNode -Command "cqlsh -e `"DESCRIBE CLUSTER;`"" -Description "cluster description" | Out-Null
}

function Show-Summary {
    param([hashtable]$NodeHealthStatus)
    
    Write-SectionHeader "Summary"
    
    $healthyNodes = ($NodeHealthStatus.Values | Where-Object { $_ -eq "healthy" }).Count
    $totalNodes = $script:NodeNames.Count
    
    Write-Host "Cluster Status: " -NoNewline
    if ($healthyNodes -eq $totalNodes) {
        Write-Host "All nodes healthy ($healthyNodes/$totalNodes)" -ForegroundColor Green
    }
    elseif ($healthyNodes -gt 0) {
        Write-Host "Partially healthy ($healthyNodes/$totalNodes nodes)" -ForegroundColor Yellow
    }
    else {
        Write-Host "No healthy nodes (0/$totalNodes)" -ForegroundColor Red
    }
    
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
}


#region Main Function

function Main {
    Write-Host "Checking Cassandra Cluster Status..." -ForegroundColor Green
    Write-Host "Script started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Check node health
    $nodeHealthStatus = Get-NodesHealthStatus
    
    # Get cluster status if any nodes are healthy
    Get-ClusterStatus -NodeHealthStatus $nodeHealthStatus
        
    # Show summary
    Show-Summary -NodeHealthStatus $nodeHealthStatus
}

#endregion

# Execute main function
Main

