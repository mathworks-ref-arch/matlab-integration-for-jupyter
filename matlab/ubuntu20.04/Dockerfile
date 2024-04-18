# Copyright 2023-2024 The MathWorks, Inc.
# Builds Docker image on Ubuntu 20.04 with: 
# 1. MATLAB - Using MPM
# 2. MATLAB Integration for Jupyter
# on a base image of jupyter/base-notebook:ubuntu-20.04

## Sample Build Command:
# docker build --build-arg MATLAB_RELEASE=r2023b \
#              --build-arg MATLAB_PRODUCT_LIST="MATLAB Deep_Learning_Toolbox Symbolic_Math_Toolbox"\
#              --build-arg LICENSE_SERVER=12345@hostname.com \
#              -t my_matlab_image_name .

# This Dockerfile uses jupyter/base-notebook:ubuntu-20.04 as its base layer
# This image only ships with Python 3.10, which limits the versions of the MATLAB Engine for Python that can be installed.
# NOTE: The MATLAB Integration for Jupyter itself will work for any version of MATLAB newer than R2020b.

## Support for MATLAB Engine for Python by Release
# For more information, see: https://mathworks.com/support/requirements/python-compatibility.html
# MATLAB RELEASE | Supported Python Versions | OS supported by matlab-deps|  Notes                          |
# ---------------|---------------------------|----------------------------|---------------------------------|
#     R2024a     |  3.9, 3.10, 3.11          | Ubuntu 22.04 & 20.04       | Use Dockerfile for ubuntu-22.04 |
#     R2023b     |  3.9, 3.10, 3.11          | Ubuntu 22.04 & 20.04       | Use Dockerfile for ubuntu-22.04 |
#     R2023a     |  3.8, 3.9, 3.10           | Ubuntu 22.04 & 20.04       | Use Dockerfile for ubuntu-22.04 |
#     R2022b     |  3.8, 3.9, 3.10           | Ubuntu 22.04 & 20.04       | Use Dockerfile for ubuntu-22.04 |
#     R2022a     |  3.8, 3.9                 | Ubuntu 20.04               | Cannot install MATLAB Engine for python |
#     R2021b     |  3.8, 3.9                 | Ubuntu 20.04               | Cannot install MATLAB Engine for python |
#     R2021a     |  3.8                      | Ubuntu 20.04               | Cannot install MATLAB Engine for python |
#     R2020b     |  3.8                      | Ubuntu 20.04               | Cannot install MATLAB Engine for python |

# Specify release of MATLAB to build. (use lowercase, default is r2024a)
ARG MATLAB_RELEASE=r2024a

# Specify the list of products to install into MATLAB, 
ARG MATLAB_PRODUCT_LIST="MATLAB Symbolic_Math_Toolbox"

# Optional Network License Server information
ARG LICENSE_SERVER

# If LICENSE_SERVER is provided then SHOULD_USE_LICENSE_SERVER will be set to "_use_lm"
ARG SHOULD_USE_LICENSE_SERVER=${LICENSE_SERVER:+"_with_lm"}

# Default DDUX information
ARG MW_CONTEXT_TAGS=MATLAB_PROXY:JUPYTER:MPM:V1

# Base Jupyter ubuntu 20.04 image  without LICENSE_SERVER
FROM jupyter/base-notebook:ubuntu-20.04 AS base_jupyter_image

# Base Jupyter ubuntu 20.04 image with LICENSE_SERVER
FROM jupyter/base-notebook:ubuntu-20.04 AS base_jupyter_image_with_lm
ARG LICENSE_SERVER
# If license server information is available, then use it to set environment variable
ENV MLM_LICENSE_FILE=${LICENSE_SERVER}

# Select base Jupyter image based on whether LICENSE_SERVER is provided
FROM base_jupyter_image${SHOULD_USE_LICENSE_SERVER}
ARG MW_CONTEXT_TAGS
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST

# Switch to root user
USER root
ENV DEBIAN_FRONTEND="noninteractive" TZ="Etc/UTC"

## Installing Dependencies for Ubuntu 20.04
# For MATLAB : Get base-dependencies.txt from matlab-deps repository on GitHub
# For mpm : wget, unzip, ca-certificates
# For MATLAB Integration for Jupyter : xvfb
# List of MATLAB Dependencies for Ubuntu 20.04 and specified MATLAB_RELEASE
ARG MATLAB_DEPS_REQUIREMENTS_FILE="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/ubuntu20.04/base-dependencies.txt"
ARG MATLAB_DEPS_REQUIREMENTS_FILE_NAME="matlab-deps-${MATLAB_RELEASE}-base-dependencies.txt"

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    wget \
    unzip \
    ca-certificates \
    xvfb \
    git \
    && wget ${MATLAB_DEPS_REQUIREMENTS_FILE} -O ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} \
    && xargs -a ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME} -r apt-get install --no-install-recommends -y \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* ${MATLAB_DEPS_REQUIREMENTS_FILE_NAME}

# Run mpm to install MATLAB in the target location and delete the mpm installation afterwards
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm && \
    ./mpm install \
    --release=${MATLAB_RELEASE} \
    --destination=/opt/matlab \
    --products ${MATLAB_PRODUCT_LIST} && \
    rm -f mpm /tmp/mathworks_root.log && \
    ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab

# Install patched glibc - See https://github.com/mathworks/build-glibc-bz-19329-patch
WORKDIR /packages
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get clean && apt-get autoremove && \
    wget -q https://github.com/mathworks/build-glibc-bz-19329-patch/releases/download/ubuntu-focal/all-packages.tar.gz && \
    tar -x -f all-packages.tar.gz \
    --exclude glibc-*.deb \
    --exclude libc6-dbg*.deb && \
    apt-get install --yes --no-install-recommends --allow-downgrades ./*.deb && \
    rm -fr /packages
WORKDIR /

# The default Python 3.10 used in this image is only supported for MATLAB releases R2024a, R2023b, R2023a, R2022b.
# Optional: Install MATLAB Engine for Python, if possible. 
# Note: Failure to install does not stop the build.
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y  python3-distutils \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && cd /opt/matlab/extern/engines/python \
    && python setup.py install || true

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install integration
RUN python -m pip install jupyter-matlab-proxy

# Make JupyterLab the default environment
ENV JUPYTER_ENABLE_LAB="yes"

ENV MW_CONTEXT_TAGS=${MW_CONTEXT_TAGS}