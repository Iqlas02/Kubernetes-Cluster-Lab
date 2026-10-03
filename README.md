# Kubernetes Cluster Lab

## Project Overview

This project documents the setup, configuration, and verification of a Kubernetes cluster built using **kubeadm** on a local VirtualBox environment.

The lab consists of one Kubernetes control-plane node and four worker nodes running Ubuntu Server ARM64 virtual machines.

The project also focuses on understanding Kubernetes PKI and creating/configuring certificates for important Kubernetes components, including **etcd** and the **kube-apiserver**.

The purpose of this repository is to document the practical work performed during the Kubernetes cluster lab, including the commands, configurations, architecture, certificate setup, verification steps, and troubleshooting performed during the implementation.

---

## Project Objectives

The main objectives of this project are:

* Build a multi-node Kubernetes cluster using `kubeadm`.
* Configure one control-plane node and multiple worker nodes.
* Configure networking between the Kubernetes nodes.
* Understand the role of Kubernetes certificates and PKI.
* Create and configure certificates for Kubernetes components.
* Configure and verify etcd certificate authentication.
* Understand the relationship between the kube-apiserver and etcd.
* Verify Kubernetes control-plane and worker-node communication.
* Verify that Kubernetes components are running correctly.
* Document troubleshooting performed during the cluster setup.

---

## Lab Environment

### Host Machine

* **Operating System:** macOS
* **Architecture:** Apple Silicon / ARM64
* **Virtualization:** VirtualBox

### Virtual Machines

The Kubernetes cluster contains five Ubuntu Server ARM64 virtual machines:

| Node            | Role                     | Host-Only IP   |
| --------------- | ------------------------ | -------------- |
| `control-plane` | Kubernetes Control Plane | `192.168.56.2` |
| `worker-1`      | Worker Node              | `192.168.56.3` |
| `worker-2`      | Worker Node              | `192.168.56.4` |
| `worker-3`      | Worker Node              | `192.168.56.5` |
| `worker-4`      | Worker Node              | `192.168.56.6` |

### Network

The VMs communicate using a VirtualBox **Host-Only Network**.

```text
                         Mac Host
                            │
                       VirtualBox
                            │
                  Host-Only Network
                   192.168.56.0/24
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
   control-plane        worker-1          worker-2
   192.168.56.2         .56.3              .56.4
          │
          │
          ├─────────────── worker-3
          │                .56.5
          │
          └─────────────── worker-4
                           .56.6
```

---

## Kubernetes Cluster Architecture

```text
                         Kubernetes Cluster
                                │
                     ┌──────────┴──────────┐
                     │                     │
                     ▼                     ▼
              Control Plane           Worker Nodes
              192.168.56.2
                     │
          ┌──────────┼──────────┐
          │          │          │
          ▼          ▼          ▼
     kube-apiserver scheduler controller-manager
          │
          │
          ▼
         etcd
          │
          │
          └────────────── Cluster State
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
           worker-1          worker-2          worker-3
           worker-4
```

---

## Main Technologies

| Technology          | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| VirtualBox          | Virtualization platform                                |
| Ubuntu Server ARM64 | Operating system for Kubernetes nodes                  |
| Kubernetes          | Container orchestration platform                       |
| kubeadm             | Kubernetes cluster bootstrap tool                      |
| kubelet             | Kubernetes node agent                                  |
| kubectl             | Kubernetes command-line client                         |
| etcd                | Kubernetes cluster state datastore                     |
| kube-apiserver      | Kubernetes API server                                  |
| CNI                 | Container networking                                   |
| Linux               | Operating system and system administration environment |

---

## Repository Structure

```text
Kubernetes-Cluster-Lab/
│
├── README.md
│
├── docs/
│   ├── architecture.md
│   ├── cluster-setup.md
│   ├── certificate-setup.md
│   └── troubleshooting.md
│
├── manifests/
│
├── scripts/
│
└── screenshots/
```

The repository will be expanded as the project documentation is added.

---

## Project Status

The Kubernetes cluster has been created and tested in the VirtualBox environment.

The next sections of this repository will document the implementation in detail, including cluster installation, certificate creation, component configuration, verification, and troubleshooting.
