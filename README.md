# Distributed Databases Decoded

Welcome to **Distributed Databases Decoded**! This repository is dedicated to demystifying distributed databases by providing hands-on examples, guides, and resources. Our goal is to help you understand the core concepts, architecture, and practical deployment of distributed databases.

## What You'll Find Here

- **Step-by-step guides** for setting up and exploring distributed databases
- **Code samples** and scripts for cluster management
- **Explanations** of key concepts and real-world use cases

## Initial Focus: Apache Cassandra

We begin our journey with [Apache Cassandra](https://cassandra.apache.org/), a highly scalable, distributed NoSQL database designed for high availability and performance. In the `cassandra/multinode-cluster` directory, you'll find resources to help you set up and experiment with a multi-node Cassandra cluster locally using Docker Compose.

### Getting Started with Cassandra

1. **Navigate to the Cassandra Cluster Setup:**
   - Go to `cassandra/multinode-cluster/`.
2. **Read the Setup Guide:**
   - See the `README.md` in that folder for detailed instructions.
3. **Start the Cluster:**
   - Use the provided PowerShell scripts (`start-cluster.ps1`) and Docker Compose file (`compose.yaml`).
4. **Check Cluster Status:**
   - Run `check-cluster-status.ps1` to verify your cluster is running.

### Folder Structure

```
cassandra/
  multinode-cluster/
    compose.yaml           # Docker Compose file for multi-node Cassandra
    start-cluster.ps1      # Script to start the cluster
    check-cluster-status.ps1 # Script to check cluster status
    README.md              # Setup and usage instructions
```

## What's Next?

We will expand this repository to cover other distributed databases, compare architectures, and provide practical labs for each. Stay tuned!

---

**Contributions and feedback are welcome!**