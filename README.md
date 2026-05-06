## Learn Salt for Windows Systems Administration

This repository contains a Vagrant-based test environment and Salt states for managing Windows Server 2025 nodes from a Rocky Linux 9 Salt Master.

## Prereqs

TBD

## Learning modes

### Vanilla: No salt pre-installed

To spin up vanilla VMs so you can follow the manual installation guide without Vagrant automation applying Salt:

```bash
VAGRANT_VANILLA_MODE=true vagrant up
```

```bash
# Alternatively, set the env var so vagrant always uses this mode
# with all subsequent `vagrant` commands
export VAGRANT_VANILLA_MODE=true
vagrant up
```

### Default: Salt master and minion pre-installed

To automatically install Salt on all nodes and map the local states to the master:

```bash
vagrant up
```

## Working with the Vagrant environment

Once up, and salt is installed, SSH into the master to apply states:

```bash
vagrant ssh master
sudo salt-key -L # See accepted minions
sudo salt '*' test.ping # Validate minions responding
sudo salt '*' state.apply # Run states
```

```bash
# Alternatively, run the commands without entering interactive ssh shell
vagrant ssh -c "sudo salt '*' test.ping" master
vagrant ssh -c "sudo salt-key -L" master # See accepted minions
vagrant ssh -c "sudo salt '*' test.ping" master # Validate minions responding
vagrant ssh -c "sudo salt '*' state.apply" master # Run states
```

## Structure

- `./salt/salt/`: Contains the Salt States.
- `./salt/pillar/`: Contains the Pillar data.
- `./docs/`: Contains the source files for documentation.
