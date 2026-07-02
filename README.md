tofu init

tofu plan -out=tfplan

tofu apply tfplan

---

ssh_host = "1.2.3.4"
ssh_user = "ansible"

---

sudo sysctl -w vm.max_map_count=262144
