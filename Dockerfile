# weft-loom-python — Python compile/run sandbox image for weft-loom.
#
# Consumed by weft-agent when a weft-loom compile job has
# language="python". Python is interpreted ; the "compile" job
# typically does : create venv, pip install, run pytest or the
# project's main script. Default command runs pytest on the
# project root.
#
# Invocation contract :
#
#   docker run --rm \
#     -v <project>:/workspace:ro \
#     -v <scratch>:/workspace/.build:rw \
#     ghcr.io/openweft/weft-loom-python \
#     /bin/sh -c "python -m venv /workspace/.build/venv && \
#                 /workspace/.build/venv/bin/pip install -r requirements.txt && \
#                 /workspace/.build/venv/bin/pytest /workspace"

FROM python:3.13-slim-bookworm

# build-essential covers numpy/scipy/cython users ; git for VCS-based
# pip installs.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        libffi-dev \
        libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Apptainer runs as the host user — the Dockerfile USER directive
# is not honoured AND the bind mount maps host file ownership
# verbatim. A non-root USER in the image creates a permission trap
# (UID 1000 in the image can't read the project tree if the host
# UID differs). Stay root ; the sandbox boundary is the workspace
# μVM, not the container user.

WORKDIR /workspace

# pip cache lives in /root.
ENV PIP_CACHE_DIR=/root/.cache/pip
# Apptainer exec uses non-login shells. Make python3 + python both
# discoverable from PATH (the python:3.13-slim base puts them at
# /usr/local/bin already but pinning here makes the contract
# explicit + survives any future image flattening).
ENV PATH=/usr/local/bin:/usr/bin:${PATH}

CMD ["/bin/sh", "-c", "python -m venv /workspace/.build/venv && /workspace/.build/venv/bin/pip install -r requirements.txt && /workspace/.build/venv/bin/pytest /workspace"]

LABEL org.opencontainers.image.title="weft-loom-python"
LABEL org.opencontainers.image.description="Python compile/run sandbox for weft-loom (Python 3.13 + build-essential + git)"
LABEL org.opencontainers.image.source="https://github.com/openweft/weft-loom-python"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
