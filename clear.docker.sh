docker system prune --all --force --volumes
sudo rm -rf /var/lib/docker
systemctl restart docker
