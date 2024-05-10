# home-service

My home service stack running on a [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) with [Fedora IoT](https://fedoraproject.org/iot/). These [podman](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) services are supporting my home infrastructure including, DNS and Kubernetes clusters.

## Core Components

- [bws-cache](https://github.com/rippleFCL/bws-cache):Integrate secrets into my infrastructure.
- [bind9](https://www.isc.org/bind/): Authoritative DNS server for my domains.
- [blocky](https://github.com/0xERR0R/blocky): Fast and lightweight ad-blocker.
- [dnsdist](https://dnsdist.org/): A DNS load balancer.
- [node-exporter](https://github.com/prometheus/node_exporter): Exporter for machine metrics.
- [podman-exporter](https://github.com/containers/prometheus-podman-exporter): Prometheus exporter for podman.
- [sops](https://github.com/getsops/sops): Manage secrets which are commited to Git.

## Setup

### System configuration

1. Install Fedora IoT on Storage(SD Card/SSD) using [arm-image-installer](https://pagure.io/arm-image-installer/releases)

    ```sh 
    sudo apt install selinux-utils -y
    export GITHUB_USER="joryirving"
    curl https://github.com/$GITHUB_USER.keys > ~/authorized_keys
    wget https://pagure.io/arm-image-installer/archive/arm-image-installer-4.1/arm-image-installer-arm-image-installer-4.1.tar.gz
    tar -xvf arm-image-installer-arm-image-installer-4.1.tar.gz
    wget https://download.fedoraproject.org/pub/alt/iot/40/IoT/aarch64/images/Fedora-IoT-raw-40-20240422.3.aarch64.raw.xz
    lsblk
    ## Note the device you're using
    sudo ./arm-image-installer-arm-image-installer-4.1/arm-image-installer --image=./Fedora-IoT-raw-40-20240422.3.aarch64.raw.xz --target=rpi4 --media=/dev/sdb --addkey=./authorized_keys --resizefs --selinux=OFF -y
    ```
> [!IMPORTANT]
> A non-root user must be created (if not already) and used.

2. Install required system deps and reboot

    ```sh
    sudo rpm-ostree install --idempotent --assumeyes git go-task
    sudo systemctl reboot
    ```

3. Make a new [SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent), add it to GitHub and clone your repo

    ```sh
    export GITHUB_USER="joryirving"
    curl https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys
    sudo mkdir -p /var/opt/home-service
    sudo chown -R $(logname):$(logname) /var/opt/home-service
    cd /var/opt/home-service
    git clone git@github.com:$GITHUB_USER/home-service.git .
    ```

4. Install additional system deps and reboot

    ```sh
    task deps
    sudo systemctl reboot
    ```

### Network configuration

> [!NOTE]
> _I am using [ipvlan](https://docs.docker.com/network/drivers/ipvlan) to expose most containers on their own IP addresses on the same network as this here device, the available addresses are mentioned in the `--ip-range` flag below. **Beware** of **IP addressing** and **interface names**._

1. Create the podman `containernet` network

    ```sh
    sudo podman network create \
        --driver=ipvlan \
        --ipam-driver=host-local \
        --subnet=192.168.1.0/24 \
        --gateway=192.168.1.1 \
        --ip-range=192.168.1.121-192.168.1.149 \
        containernet
    ```

2. Setup the currently used interface with `systemd-networkd`

    ```sh
    sudo bash -c 'cat << EOF > /etc/systemd/network/end0.network
    [Match]
    Name = end0
    [Network]
    DHCP = yes
    IPVLAN = containernet'
    ```

3. Setup `containernet` with `systemd-networkd`

    ```sh
    sudo bash -c 'cat << EOF > /etc/systemd/network/containernet.netdev
    [NetDev]
    Name = containernet
    Kind = ipvlan'
    sudo bash -c 'cat << EOF > /etc/systemd/network/containernet.network
    [Match]
    Name = containernet
    [Network]
    IPForward = yes
    Address = 192.168.1.120/24'
    ```

5. Disable `networkmanager`, the enable and start `systemd-networkd`

    ```sh
    sudo systemctl disable --now NetworkManager
    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
    ```

### Container configuration

#### bind

> [!IMPORTANT]
> _**Do not** modify the key contents after it's creation, instead create a new key using `tsig-keygen`._

1. Create the base rndc key

    ```sh
    tsig-keygen -a hmac-sha256 rndc-key > ./containers/bind/data/config/rndc.sops.key
    sops --encrypt --in-place ./containers/bind/data/config/rndc.sops.key
    ```

2. Create additional rndc keys for external-dns

    ```sh
    tsig-keygen -a hmac-sha256 kubernetes-main-key > ./containers/bind/data/config/kubernetes-main.sops.key
    tsig-keygen -a hmac-sha256 kubernetes-utility-key > ./containers/bind/data/config/kubernetes-utility.sops.key
    sops --encrypt --in-place ./containers/bind/data/config/kubernetes-main.sops.key
    sops --encrypt --in-place ./containers/bind/data/config/kubernetes-utility.sops.key
    ```

3. Update `./containers/bind/data/config` with your configuration and then start it

    ```sh
    task start-bind
    ```

#### blocky

> [!IMPORTANT]
> _Blocky can take awhile to start depending on how many blocklists you have configured_

1. Update `./containers/blocky/data/config/config.yaml` with your configuration and then start it

    ```sh
    task start-blocky
    ```

#### dnsdist

> [!IMPORTANT]
> _Prevent `systemd-resolved` from listening on port `53`_
> ```sh
> sudo bash -c 'cat << EOF > /etc/systemd/resolved.conf.d/stub-listener.conf
> [Resolve]
> DNSStubListener=no'
> sudo systemctl restart systemd-resolved
> ```

1. Update `./containers/dnsdist/data/config/dnsdist.conf` with your configuration and then start it

    ```sh
    task start-dnsdist
    ```

#### bws-cache

1. Add your `ORG_ID` to `./containers/bws-cache/bws-cache.secret`

2. Create the podman secret

    ```sh
    sudo podman secret create org_id ./containers/bws-cache/bws-cache.secret
    ```

3. Start `bws-cache`
    ```sh
    task start-bws-cache
    ```

#### node-exporter

1. Start `node-exporter`

    ```sh
    task start-node-exporter
    ```

#### podman-exporter

1. Enable the `podman.socket` service

    ```sh
    sudo systemctl enable --now podman.socket
    ```

2. Start `podman-exporter`

    ```sh
    task start-podman-exporter
    ```

#### network-utility-tools

1. Install `nut` package and reboot

    ```sh
    sudo rpm-ostree install --idempotent --assumeyes nut
    sudo systemctl reboot
    ```

2. Create password in `./ups/password.secret`

3. Enable `nut` services

    ```sh
    task boostrap-nut
    ```

### Optional configuration

#### Switch to Fish

```sh
chsh -s /usr/bin/fish
```

#### Alias go-task

> [!NOTE]
> _This is for only using the [fish shell](https://fishshell.com/)_

```sh
function task --wraps=go-task --description 'go-task shorthand'
    go-task $argv
end
funcsave task
```

#### Setup direnv

> [!NOTE]
> _This is for only using the [fish shell](https://fishshell.com/)_

```sh
echo "\
if type -q direnv
    direnv hook fish | source
end
" > ~/.config/fish/conf.d/direnv.fish
source ~/.config/fish/conf.d/direnv.fish
```

```sh
mkdir -p ~/.config/direnv
echo "\
[whitelist]
prefix = [ \"/var/opt/home-service\" ]
" > ~/.config/direnv/direnv.toml
```

#### Tune selinux

```sh
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
```

#### Disable firewalld

```sh
sudo systemctl disable --now firewalld.service
```

## Network topology

| Name | Subnet | DHCP range |
|------|--------|------------|
| LAN | 192.168.1.0/24 | 6-254 |
| GUESTS | 192.168.6.0/24 | 6-254 |
| IOT | 192.168.10.0/24 | 6-254 |
| CAMERA | 192.168.20.0/24 | 6-254 |
| TRUSTED | 192.168.30.0/24 | 6-254 |
| SERVERS | 10.69.1.0/24 | 6-254 |

## Related Projects

- [onedr0p/home-services](https://github.com/onedr0p/home-services/): Original repo where most of the config was taken from.
- [bjw-s/nix-config](https://github.com/bjw-s/nix-config/): NixOS driven configuration for running a home service machine, a nas or [nix-darwin](https://github.com/LnL7/nix-darwin) using [deploy-rs](https://github.com/serokell/deploy-rs) and [home-manager](https://github.com/nix-community/home-manager).