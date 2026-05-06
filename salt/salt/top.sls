base:
  # Apply infrastructure states to the master itself
  'salt-master':
    - master

  # Apply configurations to ALL Windows minions
  'G@os_family:Windows':
    - helloworld

  # Apply configuration to only a single minion (win2)
  'win2':
    - windows.hyperv
    - apps.vagrant
