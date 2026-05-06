# If installing against Windows:
# This state assumes the salt-winrepo-ng database has been synced to the minion.
# Instead of managing raw file downloads and `msiexec` commands, Salt handles
# finding the latest version from the community repository and installing it natively.

# If installing against Linux:
# This state will simply use the local package manager

install_vagrant:
  pkg.installed:
    - name: vagrant
