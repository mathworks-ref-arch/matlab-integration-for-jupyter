# Copyright 2020 The MathWorks, Inc.

# Replace "matlab" with the Docker image that contains MATLAB
# MATLAB should be installed at /usr/local/MATLAB or other changes will need
# to be made to this Dockerfile
FROM matlab AS matlab-install-stage

FROM jupyter/base-notebook

# Switch to root user
USER root

# Install MATLAB dependencies
# Reference: https://github.com/mathworks-ref-arch/container-images/tree/master/matlab-deps
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --no-install-recommends -y \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo-gobject2 \
        libcairo2 \
        libcrypt1 \
        libcups2 \
        libdbus-1-3 \
        libfontconfig1 \
        libgdk-pixbuf2.0-0 \
        libgstreamer-plugins-base1.0-0 \
        libgstreamer1.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpam0g \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpangoft2-1.0-0 \
        libpython2.7 \
        libpython3.8 \
        libselinux1 \
        libsm6 \
        libsndfile1 \
        libtcl8.6 \
        libuuid1 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxft2 \
        libxi6 \
        libxinerama1 \
        libxrandr2 \
        libxrender1 \
        libxt6 \
        libxtst6 \
        libxxf86vm1 \
        zlib1g \
        xkb-data \
        procps \
        ca-certificates \
        sudo \
        locales locales-all \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install jupyter-matlab-proxy dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install --yes \
        xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Put MATLAB on the PATH
RUN ln -s /usr/local/MATLAB/bin/matlab /usr/local/bin/matlab

# Copy MATLAB install from supplied Docker image
COPY --from=matlab-install-stage /usr/local/MATLAB /usr/local/MATLAB

# Switch back to notebook user
USER $NB_USER

# Install integration
RUN python -m pip install https://github.com/mathworks/jupyter-matlab-proxy/archive/0.1.0.tar.gz

# Ensure jupyter-server-proxy JupyterLab extension is installed
RUN jupyter labextension install @jupyterlab/server-proxy

# Uncomment and set the port and hostname to configure a network license manager for all users
# ENV MLM_LICENSE_FILE port@hostname
