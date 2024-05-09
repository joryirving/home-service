# home-service

My home service stack running on a [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) with [Fedora IoT](https://fedoraproject.org/iot/). These [podman](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) services are supporting my home infrastructure including, DNS and Kubernetes clusters.

## Core Components

- [bind9](https://www.isc.org/bind/): Authoritative DNS server for my domains.
- [blocky](https://github.com/0xERR0R/blocky): Fast and lightweight ad-blocker.
- [dnsdist](https://dnsdist.org/): A DNS load balancer.
- [node-exporter](https://github.com/prometheus/node_exporter): Exporter for machine metrics.
- [bws-cache](https://github.com/rippleFCL/bws-cache): Access Bitwarden secret manager.
- [podman-exporter](https://github.com/containers/prometheus-podman-exporter): Prometheus exporter for podman.

## System configuration

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
    sudo hostnamectl set-hostname --static nahida
    sudo rpm-ostree install --idempotent --assumeyes git go-task fish
    sudo systemctl reboot
    ```

3. Optional: Make a new user, add them to sudo, and enable `fish`

    ```sh
    useradd <username>
    sudo passwd <username>
    usermod -aG wheel <username>
    sudo nano /etc/passwd
    `change /bin/bash to /usr/bin/fish`
    ```

4. Make a new [SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent), add it to GitHub and clone your repo

    ```sh
    export GITHUB_USER="joryirving"
    curl https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys
    sudo mkdir -p /var/opt/home-service
    sudo chown -R $(logname):$(logname) /var/opt/home-service
    cd /var/opt/home-service
    git clone git@github.com:$GITHUB_USER/home-service.git .
    ```

5. Install additional system deps and reboot

    ```sh
    cd /var/opt/home-dns
    task deps
    sudo systemctl reboot
    ```

## Apps

### bind

> [!IMPORTANT]
> **Do not** modify the key contents after it's creation, instead create a new key using `tsig-keygen`.
1. Create the base rndc key

    ```sh
    tsig-keygen -a hmac-sha256 rndc-key > ./containers/bind/data/config/rndc.key
    ```

2. Create additional rndc keys for external-dns

    ```sh
    tsig-keygen -a hmac-sha256 kubernetes-main-key > ./containers/bind/data/config/kubernetes-main.key
    tsig-keygen -a hmac-sha256 kubernetes-pi-key > ./containers/bind/data/config/kubernetes-pi.key
    ```

3. Update `./containers/bind/data/config` with your configuration and then start it

    ```sh
    task start-bind
    ```

### blocky

> [!IMPORTANT]
> Blocky can take awhile to start depending on how many blocklists you have configured
1. Update `./containers/blocky/data/config/config.yaml` with your configuration and then start it

    ```sh
    task start-blocky
    ```

### dnsdist

> [!IMPORTANT]
> Prevent `systemd-resolved` from listening on port `53`
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

### bws-cache

1. Add your `ORG_ID` to `./containers/bws-cache/bws-cache.secret`

2. Create the podman secret

    ```sh
    sudo podman secret create org_id ./containers/bws-cache/bws-cache.secret
    ```

3. Start `bws-cache`
    ```sh
    test start-bws-cache
    ```

### node-exporter

1. Start `node-exporter`

    ```sh
    task start-node-exporter
    ```

### podman-exporter

1. Enable the `podman.socket` service

    ```sh
    sudo systemctl enable --now podman.socket
    ```

2. Start `podman-exporter`

    ```sh
    task start-podman-exporter
    ```

## Testing DNS

```sh
echo "dnsdist external query"; dig +short @192.168.1.2 -p 53 google.com | sed 's/^/  /'
echo "dnsdist internal query"; dig +short @192.168.1.2 -p 53 nas.jory.casa | sed 's/^/  /'
echo "bind external query";    dig +short @192.168.1.2 -p 5300 google.com | sed 's/^/  /'
echo "bind internal query";    dig +short @192.168.1.2 -p 5300 nas.jory.casa | sed 's/^/  /'
echo "blocky external query";  dig +short @192.168.1.2 -p 5301 google.com | sed 's/^/  /'
echo "blocky internal query";  dig +short @192.168.1.2 -p 5301 nas.jory.casa | sed 's/^/  /'
```

## Additional Apps

### NUT

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

## Optional configuration

### Alias go-task

> [!NOTE]
> This is for only using the [fish shell](https://fishshell.com/)
```sh
function task --wraps=go-task --description 'go-task shorthand'
    go-task $argv
end
funcsave task
```

### Tune selinux

```sh
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
```

### Disable firewalld

```sh
sudo systemctl mask firewalld.service
```