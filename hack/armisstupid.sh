#Run this on reboot, because ARM sucks and I hate it
sudo systemctl disable --now NetworkManager
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl disable --now firewalld.service
go-task nut:bootstrap
