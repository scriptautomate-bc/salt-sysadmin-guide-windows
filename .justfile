set shell := ["bash", "-c"]

# The designated image for container runs

version := `cat pyproject.toml | grep ^version | cut -d'"' -f2`
image := "salt-windows-sysadmin-guide-dev"
ENGINE := env_var_or_default("USE_CONTAINER_DEV", "")

# We read the environment variables natively via the shell backtick.

wrapper := `
    if [ -n "${USE_CONTAINER_DEV:-}" ]; then
        case "${USE_CONTAINER_DEV}" in
            podman|docker|container)
                echo "${USE_CONTAINER_DEV} run --rm -v ${PWD}:/workspace -w /workspace localhost/salt-windows-sysadmin-guide-dev:latest bash -c '"
                ;;
            *)
                echo ""
                ;;
        esac
    else
        echo ""
    fi
`

# Suffix to close the bash quote if running in a container wrapper

suffix := `case "${USE_CONTAINER_DEV:-}" in podman|docker|container) echo "'" ;; *) echo "" ;; esac`

# Default task lists all available tasks
default:
    @just --list

# Build the local dev container image
[group('build')]
build-container:
    @if [ -z "{{ ENGINE }}" ]; then \
        echo "USE_CONTAINER_DEV is not set. Set it to podman, docker, or container to build."; \
        exit 1; \
    fi
    {{ ENGINE }} build -t {{ image }} -f .devcontainer/Dockerfile .

# Build the docs
[group('build')]
docs:
    {{ wrapper }}uv sync{{ suffix }}
    {{ wrapper }}uv run sphinx-build -WnE --keep-going docs docs/_build/html{{ suffix }}

# Generic uv call
[group('dev')]
uv *args:
    {{ wrapper }}uv {{ args }}{{ suffix }}
