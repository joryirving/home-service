# home-service

My home service stack running on a [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) with [Fedora IoT](https://fedoraproject.org/iot/). Applications are run as [podman](https://github.com/containers/podman) containers and managed by systemd to support my home infrastructure.

## Core components

- [direnv](https://github.com/direnv/direnv): Update environment per working directory.
- [podman](https://github.com/containers/podman): A tool for managing OCI containers and pods with native [systemd](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) integration.
- [renovate](https://github.com/renovatebot/renovate): Universal dependency automation tool.
- [sops](https://github.com/getsops/sops): Manage secrets which are commited to Git using [Age](https://github.com/FiloSottile/age) for encryption.
- [task](https://github.com/go-task/task): A task runner / simpler Make alternative written in Go.

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
    sudo install -d -o $(logname) -g $(logname) -m 755 /var/opt/home-service
    git clone git@github.com:$GITHUB_USER/home-service.git /var/opt/home-service/.
    ```

4. Install additional system deps and reboot

    ```sh
    cd /var/opt/home-service
    go-task deps
    sudo systemctl reboot
    ```

5. Create an Age public/private key pair for use with sops

    ```sh
    age-keygen -o /var/opt/home-service/age.key
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

4. Disable `networkmanager`, the enable and start `systemd-networkd`

    ```sh
    sudo systemctl disable --now NetworkManager
    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
    ```

### Container configuration

> [!TIP]
> _To encrypt files with sops **replace** the **public key** in the `.sops.yaml` file with **your Age public key**. The format should look similar to the one already present._

View the [apps](./apps) directory for documentation on configuring an app container used here, or setup your own by reviewing the structure of this repository.

Using the included [Taskfile](./Taskfile.yaml) there are helper commands to start, stop, restart containers and more. Run the command below to view all available tasks.

```sh
go-task --list
```

### Optional configuration

> [!TIP]
> _[fish shell](https://fishshell.com/) is awesome, you should try fish 🐟._
> _After running the commands below logout and login again._

```sh
chsh -s /usr/bin/fish
go-task deps
```

#### Tune selinux

```sh
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
sudo systemctl reboot
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
- [truxnell/nix-config](https://github.com/truxnell/nix-config): NixOS driven configuration for running your entire homelab.