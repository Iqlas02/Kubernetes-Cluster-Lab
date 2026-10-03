````markdown
# Kubernetes Cluster Setup

This document contains the step-by-step implementation details used to build the Kubernetes cluster.

---

## 1. VirtualBox Lab Preparation

The Kubernetes cluster was created locally using VirtualBox on an Apple Silicon Mac.

### Host Environment

```text
Host OS        : macOS
Architecture   : ARM64 / Apple Silicon
Hypervisor     : VirtualBox
Guest OS       : Ubuntu Server ARM64
````

Five virtual machines were created for the Kubernetes cluster:

```text
control-plane
worker-1
worker-2
worker-3
worker-4
```

The cluster uses one control-plane node and four worker nodes.

---

## 2. Network Configuration

A VirtualBox Host-Only network was configured so that the Kubernetes nodes could communicate with each other using stable IP addresses.

The network used was:

```text
Network: 192.168.56.0/24
```

The following static IP addresses were assigned:

```text
control-plane    192.168.56.2
worker-1         192.168.56.3
worker-2         192.168.56.4
worker-3         192.168.56.5
worker-4         192.168.56.6
```

The Host-Only network was used for stable communication between the virtual machines and the Mac host.

The VMs also used their additional network configuration for external connectivity where required, such as downloading packages.

---

## 3. Verify the Network

Before installing Kubernetes, network connectivity between the nodes was verified.

For example, from a node:

```bash
ping 192.168.56.2
ping 192.168.56.3
ping 192.168.56.4
ping 192.168.56.5
ping 192.168.56.6
```

The purpose of this verification was to ensure that the nodes could communicate before proceeding with the Kubernetes installation.

A stable network is important because Kubernetes components and nodes need to communicate with each other during cluster operation.

---

## 4. Node Identification

Each VM was configured with a unique hostname so that the nodes could be easily identified.

The cluster structure was:

```text
                 Kubernetes Cluster
                        |
              +---------+---------+
              |                   |
              v                   v
        control-plane          Workers
        192.168.56.2              |
                         +---------+---------+
                         |         |         |
                         v         v         v
                      worker-1  worker-2  worker-3
                      .56.3     .56.4     .56.5
                         |
                         v
                      worker-4
                      .56.6
```

The control-plane node manages the Kubernetes control-plane components, while the worker nodes run application workloads.

---

## 5. System Preparation Overview

After preparing the virtual machines and verifying network connectivity, the Ubuntu systems were prepared for Kubernetes.

The preparation included:

* Installing the container runtime
* Configuring containerd
* Installing kubelet, kubeadm, and kubectl
* Verifying the installed components
* Preparing the system for Kubernetes cluster initialization

The container runtime selected for this project was **containerd**.

The Kubernetes components used were:

```text
containerd
    ↓
kubelet
kubeadm
kubectl
```

### Purpose of Each Component

| Component  | Purpose                                                              |
| ---------- | -------------------------------------------------------------------- |
| containerd | Runs and manages containers on the Kubernetes nodes                  |
| kubelet    | Kubernetes node agent that manages workloads on each node            |
| kubeadm    | Used to initialize and configure the Kubernetes cluster              |
| kubectl    | Command-line tool used to communicate with the Kubernetes API server |

---

## 6. Install Containerd

Kubernetes requires a container runtime to run containers on the nodes.

For this project, **containerd** was selected as the container runtime.

The package was installed using:

```bash
sudo apt install -y containerd
```

### Verify Containerd Installation

After installation, the installed containerd version was checked:

```bash
containerd --version
```

The containerd service was also checked:

```bash
systemctl status containerd --no-pager
```

These checks were used to confirm that containerd was installed and available as a system service.

### Why Containerd Is Required

Kubernetes requires a container runtime to manage the lifecycle of containers.

In this project:

```text
Kubernetes
     ↓
kubelet
     ↓
containerd
     ↓
Containers
```

Containerd therefore acts as the runtime layer used by Kubernetes nodes.

---

## 7. Configure Containerd

A configuration directory was created:

```bash
sudo mkdir -p /etc/containerd
```

A default containerd configuration was generated:

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
```

The configuration file was then edited:

```bash
sudo nano /etc/containerd/config.toml
```

The `SystemdCgroup` setting was checked using:

```bash
grep -n "SystemdCgroup" /etc/containerd/config.toml
```

After making the required configuration changes, containerd was restarted:

```bash
sudo systemctl restart containerd
```

The service was then verified:

```bash
sudo systemctl status containerd --no-pager
```

### Why Configure SystemdCgroup?

The cgroup driver controls how resource-management groups are handled on Linux.

Kubernetes and the container runtime should use compatible cgroup configuration.

In this project, containerd was configured to use the systemd cgroup driver so that it could work consistently with kubelet.

---

## 8. Install Kubernetes Components

The Kubernetes packages were installed using:

```bash
sudo apt-get install -y kubelet kubeadm kubectl
```

### kubeadm

`kubeadm` is used to bootstrap and configure a Kubernetes cluster.

It was later used to initialize the control-plane node.

### kubelet

`kubelet` is the Kubernetes node agent.

It runs on each node and communicates with the Kubernetes control plane to manage workloads assigned to that node.

### kubectl

`kubectl` is the command-line tool used to communicate with the Kubernetes API server.

For example:

```bash
kubectl get nodes
```

can be used to view the nodes registered with the cluster.

---

## 9. Hold Kubernetes Packages

The Kubernetes packages were marked as held:

```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

### Why Hold the Packages?

Holding the packages prevents them from being automatically upgraded by the package manager.

This helps keep the Kubernetes components at the versions selected for the lab.

---

## 10. Verify Kubernetes Installation

The installed Kubernetes versions were checked using:

```bash
kubectl version
```

```bash
kubeadm version
```

```bash
kubelet --version
```

These checks confirmed that the required Kubernetes commands were available before continuing with cluster initialization.

---

## 11. Prepare the Self-Created PKI Directory

The project required self-created certificates for Kubernetes control-plane components.

A dedicated working directory was created:

```bash
sudo mkdir -p /root/kubeadm-self-pki
```

The directory was used to store the certificate-generation working files and kubeadm configuration.

The existing Kubernetes PKI directories were also inspected:

```bash
sudo ls -ld /root/kubeadm-self-pki /etc/kubernetes/pki /etc/kubernetes/pki/etcd
```

The detailed certificate creation process is documented separately in:

```text
docs/certificate-setup.md
```

---

## 12. Create the Kubeadm Configuration

A kubeadm configuration file was created at:

```text
/root/kubeadm-self-pki/kubeadm-config.yaml
```

The configuration used:

```text
apiVersion: kubeadm.k8s.io/v1beta4
```

The container runtime socket configured for the cluster was:

```text
unix:///run/containerd/containerd.sock
```

The configuration was validated using:

```bash
sudo kubeadm config validate \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml
```

### Why Validate the Configuration?

Validation helps identify configuration problems before attempting to initialize the Kubernetes control plane.

This is especially useful when using a custom kubeadm configuration involving:

* Control-plane configuration
* Container runtime configuration
* Networking
* Custom certificate integration

---

## 13. Perform a Kubeadm Dry Run

Before performing the actual initialization, the certificate phase was tested using:

```bash
sudo kubeadm init phase certs all \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml \
  --dry-run
```

A complete kubeadm initialization dry run was also performed:

```bash
sudo kubeadm init \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml \
  --dry-run
```

### Why Use a Dry Run?

A dry run allows the configuration and initialization process to be checked without performing the complete live initialization.

This provides an additional validation step before making changes to the control plane.

---

## 14. Verify the Custom Certificates

After generating the self-created certificates, their properties and trust relationships were verified.

For example, certificates were inspected using OpenSSL:

```bash
sudo openssl x509 -in /root/kubeadm-self-pki/etcd-server.crt \
  -noout -subject -issuer
```

Certificate verification was performed against the appropriate CA:

```bash
sudo openssl verify \
  -CAfile /root/kubeadm-self-pki/etcd-ca.crt \
  /root/kubeadm-self-pki/etcd-server.crt
```

The generated certificate set was also verified together:

```bash
sudo openssl verify \
  -CAfile /root/kubeadm-self-pki/etcd-ca.crt \
  /root/kubeadm-self-pki/etcd-server.crt \
  /root/kubeadm-self-pki/etcd-peer.crt \
  /root/kubeadm-self-pki/etcd-healthcheck-client.crt \
  /root/kubeadm-self-pki/apiserver-etcd-client.crt
```

The detailed PKI architecture and certificate-generation commands are documented in:

```text
docs/certificate-setup.md
```

---

## 15. Integrate the Custom Certificates

The self-created certificates were copied into the Kubernetes PKI directories.

The etcd certificates were placed under:

```text
/etc/kubernetes/pki/etcd/
```

The Kubernetes control-plane certificates were placed under:

```text
/etc/kubernetes/pki/
```

The certificate integration included components such as:

```text
etcd CA
etcd server certificate
etcd peer certificate
etcd healthcheck client certificate
API server → etcd client certificate
Kubernetes CA
API server certificate
API server → kubelet client certificate
front-proxy CA
front-proxy client certificate
service-account key pair
```

Private keys were kept on the VM and were **not intended for GitHub publication**.

---

## 16. Verify Kubernetes Certificate Trust

The Kubernetes certificates were verified against the Kubernetes CA:

```bash
sudo openssl verify \
  -CAfile /etc/kubernetes/pki/ca.crt \
  /etc/kubernetes/pki/apiserver.crt \
  /etc/kubernetes/pki/apiserver-kubelet-client.crt \
  /etc/kubernetes/pki/front-proxy-client.crt
```

Certificate details were also inspected using OpenSSL to confirm their subjects, issuers, SANs, and extended key usages where applicable.

This verification helped confirm that the self-created certificates were correctly signed and suitable for their intended roles.

---

## 17. Initialize the Kubernetes Control Plane

After validating the configuration and certificate setup, the Kubernetes control plane was initialized using:

```bash
sudo kubeadm init \
  --config /root/kubeadm-self-pki/kubeadm-config.yaml
```

The initialization process configured the Kubernetes control plane according to the supplied kubeadm configuration.

After initialization, the cluster was checked using:

```bash
kubectl get nodes
```

and:

```bash
kubectl get pods -A
```

---

## 18. Install Cluster Networking

Flannel was installed as the Container Network Interface (CNI):

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

The cluster was then checked:

```bash
kubectl get pods -A
```

and:

```bash
kubectl get nodes
```

### Why a CNI Is Required

Kubernetes requires a networking solution so that pods can communicate with each other and with other parts of the cluster.

A CNI provides the networking functionality required by Kubernetes pods.

In this project, **Flannel** was used as the CNI.

---

## 19. Verify the Kubernetes Nodes

The node status was checked using:

```bash
kubectl get nodes
```

More detailed information was retrieved using:

```bash
kubectl get nodes -o wide
```

Individual nodes were also inspected:

```bash
kubectl get node control-plane -o wide
kubectl get node worker-1 -o wide
kubectl get node worker-2 -o wide
kubectl get node worker-3 -o wide
kubectl get node worker-4 -o wide
```

These commands were used to verify that the control-plane and worker nodes were registered with the cluster.

---

## 20. Verify Kubernetes System Pods

The Kubernetes system pods were inspected using:

```bash
kubectl get pods -n kube-system -o wide
```

The complete set of cluster pods was also checked:

```bash
kubectl get pods -A
```

These checks were used to verify the state of important Kubernetes components after cluster initialization.

---

## 21. Verify Flannel

Flannel pods were inspected using:

```bash
kubectl -n kube-flannel get pods -o wide
```

The Flannel DaemonSet was also checked:

```bash
kubectl -n kube-flannel get ds kube-flannel -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.template.spec.containers[0].args}{"\n"}'
```

The Flannel configuration was inspected using:

```bash
kubectl -n kube-flannel get cm kube-flannel-cfg -o yaml
```

The rollout status was checked using:

```bash
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds
```

These checks helped verify the CNI deployment and troubleshoot pod-networking issues.

---

## 22. Verify Kubelet

The kubelet systemd service was inspected using:

```bash
systemctl cat kubelet
```

The kubeadm-generated kubelet flags were inspected using:

```bash
cat /var/lib/kubelet/kubeadm-flags.env
```

The kubelet configuration file was checked using:

```bash
cat /etc/default/kubelet 2>/dev/null || echo "File does not exist"
```

The kubelet service was restarted when required:

```bash
sudo systemctl restart kubelet
```

Its active state was verified using:

```bash
systemctl is-active kubelet
```

---

## 23. Verify Kubernetes Certificate Expiration

Kubernetes certificate expiration was checked using:

```bash
sudo kubeadm certs check-expiration
```

This command provides information about the expiration dates of certificates managed by kubeadm.

Certificate expiration checks are important because expired control-plane certificates can prevent Kubernetes components from communicating correctly.

---

## 24. Final Cluster Verification

The final cluster state was checked using:

```bash
kubectl get nodes -o wide
```

and:

```bash
kubectl get pods -A
```

The cluster was also tested with an example NGINX workload during the lab.

The deployment was created using:

```bash
kubectl apply -f ~/nginx-deployment.yaml
```

The deployment was checked using:

```bash
kubectl get deployments
```

The pods were inspected using:

```bash
kubectl get pods -o wide
```

The NGINX service was then created using:

```bash
kubectl apply -f ~/nginx-service.yaml
```

The service was verified using:

```bash
kubectl get service nginx
```

Endpoints were checked using:

```bash
kubectl get endpoints nginx
```

This provided an application-level verification that workloads could be deployed and exposed through Kubernetes.

---

## 25. Project Result

The final lab architecture can be summarized as:

```text
                         Mac Host
                            |
                        VirtualBox
                            |
              +-------------+-------------+
              |                           |
        Host-Only Network             External/NAT
        192.168.56.0/24              connectivity
              |
       +------+------+
       |             |
       v             v
 Control Plane     Workers
 192.168.56.2        |
       |       +-----+-----+-----+
       |       |           |     |
       |       v           v     v
       |    worker-1    worker-2 worker-3
       |    .56.3       .56.4    .56.5
       |                         |
       |                         v
       |                      worker-4
       |                      .56.6
       |
       +--> kubeadm
       +--> kubelet
       +--> kubectl
       +--> containerd
       +--> etcd
       +--> kube-apiserver
       +--> Flannel
```

The project demonstrated:

* VirtualBox-based Kubernetes infrastructure
* Ubuntu Server ARM64 nodes
* Host-Only networking
* containerd configuration
* kubeadm-based cluster initialization
* kubelet and kubectl usage
* self-created Kubernetes PKI
* self-created etcd certificates
* kube-apiserver certificate configuration
* certificate verification using OpenSSL
* Flannel CNI deployment
* Kubernetes node and system-pod verification
* kubelet troubleshooting and verification
* certificate-expiration verification
* application deployment using NGINX

