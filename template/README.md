# My Miniguest guests

To create and start a VM, run
```sh
sudo miniguest install .#stateless
virsh create --console --autodestroy guests/stateless/domain.xml
```
