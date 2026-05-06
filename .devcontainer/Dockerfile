FROM python:3.14

RUN apt-get update && apt-get install jq shellcheck vim just -y

# Install uv
RUN pip install uv

# Sync deps
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project

# Prep system
RUN rm -rf /var/lib/apt/lists/*

# Prep bash profile for using uv installed tools via "uv tool install"
RUN mkdir -p /root/.local/bin
RUN echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc
RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /root/.bashrc

# Set working directory
WORKDIR /workspace
