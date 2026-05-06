# Ensures the Hyper-V role and its management tools are installed on Windows Server.
# Note: Installing Hyper-V usually requires a system reboot to fully take effect.

install_hyperv_role:
  win_servermanager.installed:
    - name: Hyper-V
    - include_management_tools: True
