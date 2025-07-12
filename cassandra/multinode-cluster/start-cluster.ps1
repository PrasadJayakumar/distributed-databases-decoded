# PowerShell script to create required folders and start the Cassandra multinode cluster

# Create required data directories for all nodes
New-Item -ItemType Directory -Path "./volume-data/node1" -Force | Out-Null
New-Item -ItemType Directory -Path "./volume-data/node2" -Force | Out-Null
New-Item -ItemType Directory -Path "./volume-data/node3" -Force | Out-Null
New-Item -ItemType Directory -Path "./volume-data/node4" -Force | Out-Null

# Start the multinode Cassandra cluster using Docker Compose
Write-Host "Starting Cassandra multinode cluster..."
docker-compose up -d

Write-Host "Cluster startup initiated. Use 'docker compose ps' to check status."
