# Kubernetes Troubleshooting

This document records the main issues encountered while building and validating the Kubernetes cluster and the steps used to troubleshoot them.

---

## 1. VM Network Connectivity

### Problem

The Kubernetes nodes needed to communicate with each other using stable IP addresses.

### Solution

A VirtualBox Host-Only network was configured:

```text
192.168.56.0/24
```

The nodes were assigned:

```text
control-plane    192.168.56.2
worker-1         192.168.56.3
worker-2         192.168.56.4
worker-3         192.168.56.5
worker-4         192.168.56.6
```

Connectivity was verified using:

```bash
ping 192.168.56.2
ping 192.168.56.3
ping 192.168.56.4
ping 192.168.56.5
ping 192.168.56.6
```

---

## 2. Containerd Not Available

### Problem

Kubernetes requires a container runtime to run containers.

During the setup, containerd was checked and installed where required.

### Verification

```bash
containerd --version
```

```bash
systemctl status containerd --no-pager
```

### Installation

```bash
sudo apt install -y containerd
```

---

## 3. Containerd Configuration

### Problem

Kubernetes and containerd need compatible cgroup configuration.

The containerd configuration was generated:

```bash
sudo mkdir -p /etc/containerd
```

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
```

The configuration was then reviewed and updated.

The `SystemdCgroup` setting was checked using:

```bash
grep -n "SystemdCgroup" /etc/containerd/config.toml
```

After configuration, containerd was restarted:

```bash
sudo systemctl restart containerd
```

and verified:

```bash
sudo systemctl status containerd --no-pager
```

---

## 4. Kubernetes Package Verification

The Kubernetes components were verified after installation.

```bash
kubeadm version
```

```bash
kubelet --version
```

```bash
kubectl version
```

The purpose was to confirm that the required Kubernetes tools were installed and accessible.

---

## 5. Kubelet Configuration

### Problem

The kubelet configuration required verification during cluster setup.

The kubelet service configuration was inspected:

```bash
systemctl cat kubelet
```

The kubeadm-generated flags were checked:

```bash
cat /var/lib/kubelet/kubeadm-flags.env
```

The optional kubelet configuration file was checked:

```bash
cat /etc/default/kubelet 2>/dev/null || echo "File does not exist"
```

When configuration changes were required, the kubelet was restarted:

```bash
sudo systemctl restart kubelet
```

Its state was then checked:

```bash
systemctl is-active kubelet
```

---

## 6. Flannel Networking Issue

### Problem

Flannel required verification after the Kubernetes cluster was initialized.

The Flannel pods were inspected:

```bash
kubectl -n kube-flannel get pods -o wide
```

Pod logs were checked when troubleshooting was required:

```bash
kubectl -n kube-flannel logs <FLANNEL-POD-NAME> -c kube-flannel
```

The Flannel DaemonSet configuration was inspected:

```bash
kubectl -n kube-flannel get ds kube-flannel-ds -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.template.spec.containers[0].args}{"\n"}'
```

The Flannel configuration was also inspected:

```bash
kubectl -n kube-flannel get cm kube-flannel-cfg -o yaml
```

The network interface used by Flannel was explicitly configured during troubleshooting:

```bash
kubectl -n kube-flannel patch daemonset kube-flannel-ds \
  --type='strategic' \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"kube-flannel","args":["--ip-masq","--kube-subnet-mgr","--iface=enp0s9"]}]}}}}'
```

The resulting pods were checked:

```bash
kubectl -n kube-flannel get pods -o wide
```

The rollout was verified:

```bash
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds
```

### Lesson

When a CNI plugin has networking problems, checking the node's network interfaces and the CNI configuration is an important troubleshooting step.

---

## 7. Kubernetes Node Verification

The cluster node state was checked using:

```bash
kubectl get nodes
```

More detailed information was obtained using:

```bash
kubectl get nodes -o wide
```

Individual nodes could also be checked:

```bash
kubectl get node control-plane -o wide
kubectl get node worker-1 -o wide
kubectl get node worker-2 -o wide
kubectl get node worker-3 -o wide
kubectl get node worker-4 -o wide
```

This helped verify:

* Node registration
* Internal IP addresses
* Kubernetes versions
* Node readiness

---

## 8. Kubernetes System Pod Verification

All system pods were checked with:

```bash
kubectl get pods -A
```

The kube-system namespace was also inspected:

```bash
kubectl get pods -n kube-system -o wide
```

This was useful for identifying problems with components such as:

* CoreDNS
* kube-proxy
* kube-apiserver
* kube-controller-manager
* kube-scheduler
* etcd

---

## 9. Certificate Verification Problems

Because the project used self-created certificates, certificate verification was an important troubleshooting step.

Certificates were inspected using:

```bash
sudo openssl x509 \
  -in /path/to/certificate.crt \
  -noout \
  -subject \
  -issuer
```

Certificate chains were verified using:

```bash
sudo openssl verify \
  -CAfile /path/to/ca.crt \
  /path/to/certificate.crt
```

For certificates where SANs were important:

```bash
sudo openssl x509 \
  -in /path/to/certificate.crt \
  -noout \
  -subject \
  -issuer \
  -ext subjectAltName
```

For client certificates, Extended Key Usage was also inspected:

```bash
sudo openssl x509 \
  -in /path/to/certificate.crt \
  -noout \
  -subject \
  -issuer \
  -ext extendedKeyUsage
```

### Lesson

When debugging Kubernetes TLS problems, check:

1. Certificate subject
2. Certificate issuer
3. Certificate expiration
4. Subject Alternative Names
5. Extended Key Usage
6. CA trust
7. Correct certificate file path

---

## 10. Kubeadm Configuration Validation

Before initializing the cluster, the kubeadm configuration was validated:

```bash
sudo kubeadm config validate \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml
```

A certificate-generation dry run was also performed:

```bash
sudo kubeadm init phase certs all \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml \
  --dry-run
```

A complete initialization dry run was performed:

```bash
sudo kubeadm init \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml \
  --dry-run
```

### Lesson

Using validation and dry-run operations before actual cluster initialization helps identify configuration problems before making changes to the cluster.

---

## 11. Certificate Expiration Check

Kubernetes certificate expiration was checked using:

```bash
sudo kubeadm certs check-expiration
```

This provides visibility into certificate validity periods and helps identify certificates approaching expiration.

---

## 12. NGINX Application Verification

After the cluster and networking were working, an NGINX deployment was used to verify application scheduling and service connectivity.

The deployment was checked using:

```bash
kubectl get deployments
```

Pods were checked using:

```bash
kubectl get pods -o wide
```

The NGINX deployment was inspected:

```bash
kubectl get deployment nginx
```

The service was created and inspected:

```bash
kubectl apply -f ~/nginx-service.yaml
```

```bash
kubectl get service nginx
```

Endpoints were checked using:

```bash
kubectl get endpoints nginx
```

The purpose of this test was to verify that the cluster could successfully run a workload and expose it through a Kubernetes Service.

---

# 13. General Troubleshooting Approach

The troubleshooting process followed a layered approach:

```text
VM / Hardware
      ↓
Network
      ↓
Container Runtime
      ↓
Kubelet
      ↓
Kubernetes Control Plane
      ↓
CNI / Cluster Networking
      ↓
Kubernetes Nodes
      ↓
Application Workload
```

When a problem occurs, troubleshooting should generally begin from the lower layer and move upward.

For example:

```text
Pod not working
     ↓
Check pod status
     ↓
Check pod logs
     ↓
Check node status
     ↓
Check kubelet
     ↓
Check containerd
     ↓
Check CNI/network
```

This layered approach prevents troubleshooting from becoming random trial and error.

---

# 14. Useful Commands Reference

### Cluster

```bash
kubectl get nodes
kubectl get nodes -o wide
kubectl get pods -A
```

### Workloads

```bash
kubectl get deployments
kubectl get pods -o wide
kubectl get services
```

### Node troubleshooting

```bash
systemctl status kubelet --no-pager
systemctl is-active kubelet
```

### Container runtime

```bash
containerd --version
systemctl status containerd --no-pager
```

### Flannel

```bash
kubectl -n kube-flannel get pods -o wide
kubectl -n kube-flannel get ds kube-flannel-ds
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds
```

### Certificates

```bash
sudo kubeadm certs check-expiration
```

```bash
sudo openssl x509 -in certificate.crt -noout -subject -issuer
```

```bash
sudo openssl verify --CAfile ca.crt certificate.crt
```

---

# 15. Final Outcome

The troubleshooting process helped verify and stabilize the Kubernetes cluster.

The completed environment included:

* Five Ubuntu ARM64 virtual machines
* One control-plane node
* Four worker nodes
* Host-Only networking
* containerd
* kubeadm
* kubelet
* kubectl
* Self-created Kubernetes PKI
* Self-created etcd certificates
* kube-apiserver certificate configuration
* Flannel CNI
* Kubernetes system pods
* NGINX workload

The troubleshooting work demonstrated practical skills in:

* Linux system administration
* Networking
* Kubernetes diagnostics
* Container runtime troubleshooting
* kubelet troubleshooting
* CNI troubleshooting
* TLS/PKI troubleshooting
* Application verification
* Command-line investigation
