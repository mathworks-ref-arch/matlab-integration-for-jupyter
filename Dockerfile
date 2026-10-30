# Copyright 2024-2026 The MathWorks, Inc.
# Dockerfile for the MATLAB Integration for Jupyter based on quay.io/jupyter/base-notebook
# With Python Version : 3.13
###############################################################################
# This Dockerfile is divided into multiple stages, the behavior of each stage
#         is based on the build time args.
#  Stage 1 : Base Layer + matlab-deps (release & OS specific)
#  Stage 2 : Install MATLAB (Either from MPM, mounted, or your own image)
#  Stage 2a : MathWorks Service Host (MSH) is installed if MATLAB is installed using MPM
#  Stage 3 : Install MATLAB Engine for Python
#  Stage 4 : Install MATLAB Integration for Jupyter
#  Stage 5 : Embed LICENSE_SERVER information
# This Dockerfile is based on the concept explained here.
# See: https://github.com/docker/cli/issues/1134#issuecomment-405946645
###############################################################################

# Example docker build commands are available at the end of this file.

## Setup Build Arguments, to chain multi-stage build selection.
ARG MATLAB_RELEASE=R2026b

# See https://mathworks.com/help/install/ug/mpminstall.html for product list specfication
ARG MATLAB_PRODUCT_LIST="MATLAB"

# Default installation directory for MATLAB
ARG MATLAB_INSTALL_LOCATION="/opt/matlab"

# MATLAB_INSTALL_STAGE_SELECTOR selects the build stage from which MATLAB will be derived from.
# Values are based on the names of the stages that use them: using-mpm, from-mount, from-image

# Mounting MATLAB, at docker run time, ensure that you mount your MATLAB into ${MATLAB_INSTALL_LOCATION}
ARG MOUNT_MATLAB
# if mount is provided, set source to "from-mount"
ARG MATLAB_INSTALL_STAGE_SELECTOR=${MOUNT_MATLAB:+"from-mount"}

# Bring your own Image
# Example: mathworks/matlab:r2024b
ARG MATLAB_IMAGE_NAME
# Argument shared across multi-stage build to hold location of installed MATLAB 
ARG MATLAB_INSTALL_LOCATION_PLACEHOLDER=/tmp/matlab-install-location
# If image is provided, set a temp value to "from-image"
ARG MATLAB_SOURCE_TEMP=${MATLAB_IMAGE_NAME:+"from-image"}
# If temp value is set, then set it as source, else carry forward result from mount
ARG MATLAB_INSTALL_STAGE_SELECTOR=${MATLAB_SOURCE_TEMP:-${MATLAB_INSTALL_STAGE_SELECTOR}}

# If source is still unset, then use the default 
ARG MATLAB_INSTALL_STAGE_SELECTOR=${MATLAB_INSTALL_STAGE_SELECTOR:-"using-mpm"}

# Build argument to control the installation of MATLAB Engine for Python
ARG INSTALL_MATLABENGINE
ARG MEFP=${INSTALL_MATLABENGINE:+"-with-engine"}

# Build argument to control the installation of jupyter-remote-desktop-proxy
ARG INSTALL_VNC
ARG VNC=${INSTALL_VNC:+"-with-vnc"}

# Sets NLM to "with-nlm" if LICENSE_SERVER value is defined
ARG LICENSE_SERVER
ARG NLM=${LICENSE_SERVER:+"-with-nlm"}

# Python 3.12 is the default version in Ubuntu 24.04
ARG UBUNTU_VERSION=24.04

######################################
#  Stage 1 : Base Layer + matlab-deps
######################################
FROM quay.io/jupyter/base-notebook:ubuntu-${UBUNTU_VERSION} AS base1
ARG UBUNTU_VERSION
ARG MATLAB_RELEASE
ARG TARGET_ARCH=amd64
RUN echo "Installing dependencies for MATLAB ${MATLAB_RELEASE} on Ubuntu ${UBUNTU_VERSION}..."

USER root

ARG MATLAB_DEPS_URL="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/ubuntu${UBUNTU_VERSION}/base-dependencies-${TARGET_ARCH}.txt"
ARG MATLAB_DEPENDENCIES="matlab-deps-${MATLAB_RELEASE}-base-dependencies-${TARGET_ARCH}.txt"
ARG ADDITIONAL_PACKAGES="wget curl unzip ca-certificates xvfb git vim fluxbox openbox"
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y ${ADDITIONAL_PACKAGES}\
    && wget $(echo ${MATLAB_DEPS_URL} | tr "[:upper:]" "[:lower:]") -O ${MATLAB_DEPENDENCIES} \
    && xargs -a ${MATLAB_DEPENDENCIES} -r apt-get install --no-install-recommends -y \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* ${MATLAB_DEPENDENCIES}

#####################################################
#  Stage 2 : Install MATLAB
#   Sub-Stage A: Installs MATLAB using MPM
#   Sub-Stage B: Uses Mounted MATLAB
#   Sub-Stage C: Copies MATLAB from existing Image
#####################################################

##########################################
#  Sub-Stage A: Installs MATLAB using MPM and includes MSH
##########################################
FROM base1 AS install-matlab-using-mpm
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST
ARG MATLAB_INSTALL_LOCATION

WORKDIR /matlab-install
ARG MSH_MANAGED_INSTALL_ROOT=/usr/local/MathWorks/ServiceHost/
ARG MSH_DOWNLOAD_LOCATION=/tmp/Downloads/MathWorks/ServiceHost
# Dont need to set HOME to install Support packages as jupyter images set HOME to NB_USER in all images, even for ROOT.
RUN echo "Installing MATLAB using MPM..."
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm \
    && ./mpm install --release=${MATLAB_RELEASE} --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false)\
    && rm -f mpm /tmp/mathworks_root.log \
    && ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab \
    && git clone https://github.com/mathworks-ref-arch/administer-mathworks-service-host.git \
    && cd /matlab-install/administer-mathworks-service-host/admin-scripts/linux/admin-controlled-installation \
    && ./download_msh.sh --destination ${MSH_DOWNLOAD_LOCATION} \
    && ./install_msh.sh --source ${MSH_DOWNLOAD_LOCATION} --destination ${MSH_MANAGED_INSTALL_ROOT} --no-update-environment \
    && ./cleanup_default_msh_installation_location.sh --for-all-users \
    && cd / && rm -rf /matlab-install ${MSH_DOWNLOAD_LOCATION}

ENV MATHWORKS_SERVICE_HOST_MANAGED_INSTALL_ROOT=${MSH_MANAGED_INSTALL_ROOT}
WORKDIR /root

######################################
#  Sub-Stage B: Uses Mounted MATLAB
######################################
FROM base1 AS install-matlab-from-mount
ARG MATLAB_INSTALL_LOCATION
RUN echo "Mounting MATLAB from ${MATLAB_INSTALL_LOCATION}..."
RUN ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab

#################################################
#  Sub-Stage C: Copies MATLAB from existing Image
#################################################
# Provide a default value for the BYOI stage base image
FROM ${MATLAB_IMAGE_NAME:-scratch} AS matlab-install-stage
ARG MATLAB_INSTALL_LOCATION_PLACEHOLDER
# Run code to locate a MATLAB install in the base image and softlink
# to MATLAB_INSTALL_LOCATION_PLACEHOLDER for a latter stage to copy 
RUN export LOCAL_INSTALL_LOCATION=$(which matlab) \
    && if [ ! -z "$LOCAL_INSTALL_LOCATION" ]; then \
    LOCAL_INSTALL_LOCATION=$(dirname $(dirname $(readlink -f ${LOCAL_INSTALL_LOCATION}))); \
    echo "soft linking: " $LOCAL_INSTALL_LOCATION " to" ${MATLAB_INSTALL_LOCATION_PLACEHOLDER}; \
    ln -s ${LOCAL_INSTALL_LOCATION} ${MATLAB_INSTALL_LOCATION_PLACEHOLDER}; \
    elif [ $MATLAB_INSTALL_LOCATION_PLACEHOLDER = '/tmp/matlab-install-location' ]; then \
    echo "MATLAB was not found in your image."; exit 1; \
    else \
    echo "Proceeding with user provided path to MATLAB installation: ${MATLAB_INSTALL_LOCATION_PLACEHOLDER}"; \
    fi

FROM base1 AS install-matlab-from-image
ARG MATLAB_INSTALL_LOCATION
ARG MATLAB_INSTALL_LOCATION_PLACEHOLDER
RUN echo "Copying MATLAB found in ${MATLAB_INSTALL_LOCATION_PLACEHOLDER} from your image to ${MATLAB_INSTALL_LOCATION}..."
COPY --from=matlab-install-stage ${MATLAB_INSTALL_LOCATION_PLACEHOLDER} ${MATLAB_INSTALL_LOCATION}
RUN ln -fs ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab

# PICK image from which you will get MATLAB
FROM install-matlab-${MATLAB_INSTALL_STAGE_SELECTOR} AS base2
USER $NB_USER
WORKDIR /home/${NB_USER}
RUN echo "MATLAB Installation Complete."

##################################################################################################################
#  Stage 3 : Install MATLAB Engine for Python
# Installation can fail if :
# 1. Python Version is incompatible.
#       For more information, see https://mathworks.com/support/requirements/python-compatibility.html
# 2. MATLAB installation is not found, which is always true if you are mounting MATLAB at runtime.
#
# Failure to install does not stop the build
##################################################################################################################
FROM base2 AS base2-with-engine
ARG MATLAB_INSTALL_LOCATION
RUN echo "Installing MATLAB Engine for Python..."
RUN MATLAB_VERSION=$(cat ${MATLAB_INSTALL_LOCATION}/VersionInfo.xml | grep -oP '(\d{2}\.\d{1})') && \
     env LD_LIBRARY_PATH=${MATLAB_INSTALL_LOCATION}/bin/glnxa64 python -m pip install -U matlabengine==${MATLAB_VERSION}.* || \
     echo "Failed to install MATLAB Engine for Python... skipping ..."

# PICK image with/without engine
FROM base2${MEFP} AS base3

#####################################################
#  Stage 4 : Install MATLAB Integration for Jupyter
#####################################################
FROM base3 AS base3-with-jmp
RUN echo "Installing jupyter-matlab-proxy..."
# Specify the URL to override the pip package index URL.
# Leave blank to use the default PyPi repository.
ARG PIP_INDEX_URL
RUN PIP_INDEX_URL=${PIP_INDEX_URL} python -m pip install -U jupyter-matlab-proxy


FROM base3-with-jmp AS base3-with-jmp-with-vnc
RUN echo "Installing jupyter-remote-desktop-proxy ..."
# Specify the URL to override the pip package index URL.
# Leave blank to use the default PyPi repository.
ARG PIP_INDEX_URL
RUN PIP_INDEX_URL=${PIP_INDEX_URL} python -m pip install -U jupyter-remote-desktop-proxy
USER root

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update \
    && apt-get install --no-install-recommends -y \
    dbus-x11 \
    firefox \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    tigervnc-standalone-server \
    # Disable the automatic screenlock since the account password is unknown
    && apt-get -y -qq remove xfce4-screensaver 

USER $NB_USER

COPY --chown=$NB_UID:$NB_GID ./resources /home/${NB_USER}/matlab-resources
# Move MATLAB resource files to the expected locations. Also create Documents folder
# as MATLAB will warn if it does not exist.
RUN export RESOURCES_LOC=/home/${NB_USER}/matlab-resources \
    && mkdir -p ${HOME}/.local/share/applications ${HOME}/Desktop ${HOME}/Documents ${HOME}/.local/share/ ${HOME}/.icons \
    && cp ${RESOURCES_LOC}/MATLAB.desktop ${HOME}/Desktop/ \
    && cp ${RESOURCES_LOC}/MATLAB.desktop ${HOME}/.local/share/applications\
    && ln -s ${RESOURCES_LOC}/matlab_icon.png ${HOME}/.icons/matlab_icon.png

FROM base3-with-jmp${VNC} AS base4
RUN echo "Python Package Installation Complete."

#####################################################
#  Stage 5 : Embed LICENSE_SERVER information
#####################################################
FROM base4 AS base4-with-nlm
ARG LICENSE_SERVER
RUN echo "Setting MLM_LICENSE_FILE to ${LICENSE_SERVER}"
ENV MLM_LICENSE_FILE=${LICENSE_SERVER}

FROM base4${NLM} AS final

FROM final
RUN echo "Done."
USER $NB_USER

# Create the MATLAB documents directory
RUN mkdir -p "${HOME}/Documents/MATLAB"
ENV MW_CONTEXT_TAGS=MATLAB_PROXY:JUPYTER:V1


#####################################################
#####################################################

### Dockerfile build configurations:
# 1. MATLAB from MPM + JMP 
#  docker build -t mifj:mpm .

# 2. MATLAB from MPM + JMP + MEFP
#  docker build -t mifj:mpm --build-arg INSTALL_MATLABENGINE=1 .

# 3. MATLAB from MPM + JMP + VNC
#  docker build -t mifj:mpm --build-arg INSTALL_VNC=1 .

# 4. MATLAB from MPM + JMP + LICENSE_SERVER
#  docker build -t mifj:mpm --build-arg LICENSE_SERVER=port@hostname .

# 5. Mounted MATLAB
#  docker build -t mifj:mpm  --build-arg MOUNT_MATLAB=1 .

# 6. BYOI MATLAB Image, MATLAB_RELEASE is required to install the right dependencies
#  docker build -t mifj:mpm --build-arg MATLAB_IMAGE_NAME=mathworks/matlab:r2024b MATLAB_RELEASE=R2024b .
