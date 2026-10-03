#!/bin/bash

# ============================================================
# Kubernetes Cluster Verification
# ============================================================
#
# Purpose:
#   Performs read-only health and configuration checks on a
#   Kubernetes cluster using kubectl.
#
# Checks:
#   - Cluster nodes
#   - Kubernetes pods
#   - Flannel CNI
#   - Deployments
#   - Services
#   - Kubernetes version
#
# Note:
#   This script does not create, modify, or delete resources.
# ============================================================

set -e

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------

print_section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}


# ------------------------------------------------------------
# Verify kubectl is available
# ------------------------------------------------------------

if ! command -v kubectl >/dev/null 2>&1; then
    echo "ERROR: kubectl is not installed or not available in PATH."
    exit 1
fi


# ------------------------------------------------------------
# Verify Kubernetes cluster access
# ------------------------------------------------------------

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "ERROR: Unable to connect to the Kubernetes cluster."
    echo "Check your kubeconfig and cluster availability."
    exit 1
fi


# ------------------------------------------------------------
# 1. Kubernetes Nodes
# ------------------------------------------------------------

print_section "1. Kubernetes Nodes"

kubectl get nodes -o wide


# ------------------------------------------------------------
# 2. Kubernetes Pods
# ------------------------------------------------------------

print_section "2. Kubernetes Pods"

kubectl get pods -A


# ------------------------------------------------------------
# 3. Flannel CNI
# ------------------------------------------------------------

print_section "3. Flannel CNI"

kubectl get pods -n kube-flannel -o wide


# ------------------------------------------------------------
# 4. Deployments
# ------------------------------------------------------------

print_section "4. Kubernetes Deployments"

kubectl get deployments -A


# ------------------------------------------------------------
# 5. Services
# ------------------------------------------------------------

print_section "5. Kubernetes Services"

kubectl get services -A


# ------------------------------------------------------------
# 6. Kubernetes Version
# ------------------------------------------------------------

print_section "6. Kubernetes Version"

kubectl version


# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

print_section "Verification Completed"

echo "Kubernetes cluster verification completed successfully."
