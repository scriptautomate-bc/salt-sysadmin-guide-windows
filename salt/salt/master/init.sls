# Ensure EPEL and development tools are installed for building
# Python C-extensions if needed
install_build_deps:
  pkg.installed:
    - pkgs:
      - gcc
      - make
      - cmake
      - libgit2-devel

# Salt 3006+ uses a bundled Python environment (Relenv)
# We must use the bundled pip to install pygit2 so Salt can import it
# This bundled pip is used by default with `pip.install`
install_pygit2_for_salt:
  pip.installed:
    - name: pygit2
    - require:
      - pkg: install_build_deps

# Configure the Windows Package Manager repository
configure_winrepo_gitfs:
  file.managed:
    - name: /etc/salt/master.d/winrepo.conf
    - contents: |
        winrepo_provider: pygit2
        winrepo_remotes:
          - 'https://github.com/saltstack/salt-winrepo-ng.git'
    - makedirs: True

# Restart the Salt Master so the new Python modules and config files take effect
restart_salt_master:
  service.running:
    - name: salt-master
    - watch:
      - file: configure_winrepo_gitfs
      - pip: install_pygit2_for_salt
