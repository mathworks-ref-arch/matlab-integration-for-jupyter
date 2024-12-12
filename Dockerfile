# Copyright 2024 The MathWorks, Inc.
# Dockerfile for the MATLAB Integration for Jupyter based on quay.io/jupyter/base-notebook
# With Python Version : 3.11
###############################################################################
# This Dockerfile is divided into multiple stages, the behavior of each stage
#         is based on the build time args.
#  Stage 1 : Base Layer + matlab-deps (release & OS specific)
#  Stage 2 : Install MATLAB (Either from MPM, mounted, or your own image)
#  Stage 3 : Install MATLAB Engine for Python
#  Stage 4 : Install MATLAB Integration for Jupyter
#  Stage 5 : Embed LICENSE_SERVER information
# This Dockerfile is based on the concept explained here.
# See: https://github.com/docker/cli/issues/1134#issuecomment-405946645
###############################################################################

# Example docker build commands are available at the end of this file.

## Setup Build Arguments, to chain multi-stage build selection.
ARG MATLAB_RELEASE=R2024b

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

# Build argument to control the installation of jupyter-matlab-vnc-proxy
ARG INSTALL_VNC
ARG VNC=${INSTALL_VNC:+"-with-vnc"}

# Sets NLM to "with-nlm" if LICENSE_SERVER value is defined
ARG LICENSE_SERVER
ARG NLM=${LICENSE_SERVER:+"-with-nlm"}

# Both 22.04 & 24.04 ship with Python 3.11
ARG UBUNTU_VERSION=22.04

######################################
#  Stage 1 : Base Layer + matlab-deps
######################################
FROM quay.io/jupyter/base-notebook:ubuntu-${UBUNTU_VERSION} AS base1
ARG UBUNTU_VERSION
ARG MATLAB_RELEASE
RUN echo "Installing dependencies for MATLAB ${MATLAB_RELEASE} on Ubuntu ${UBUNTU_VERSION}..."

USER root

ARG MATLAB_DEPS_URL="https://raw.githubusercontent.com/mathworks-ref-arch/container-images/main/matlab-deps/${MATLAB_RELEASE}/ubuntu${UBUNTU_VERSION}/base-dependencies.txt"
ARG MATLAB_DEPENDENCIES="matlab-deps-${MATLAB_RELEASE}-base-dependencies.txt"
ARG ADDITIONAL_PACKAGES="wget curl unzip ca-certificates xvfb git vim"
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
#  Sub-Stage A: Installs MATLAB using MPM
##########################################
FROM base1 AS install-matlab-using-mpm
ARG MATLAB_RELEASE
ARG MATLAB_PRODUCT_LIST
ARG MATLAB_INSTALL_LOCATION

# Dont need to set HOME to install Support packages as jupyter images set HOME to NB_USER in all images, even for ROOT.
RUN echo "Installing MATLAB using MPM..."
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \ 
    chmod +x mpm \
    && ./mpm install --release=${MATLAB_RELEASE} --destination=${MATLAB_INSTALL_LOCATION} \
    --products ${MATLAB_PRODUCT_LIST} \
    || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && false)\
    && rm -f mpm /tmp/mathworks_root.log \
    && ln -s ${MATLAB_INSTALL_LOCATION}/bin/matlab /usr/local/bin/matlab

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
RUN python -m pip install -U jupyter-matlab-proxy

FROM base3-with-jmp AS base3-with-jmp-with-vnc
RUN echo "Installing jupyter-matlab-vnc-proxy ..."
USER root

# noVNC provides VNC over browser capability
# Set default install location for noVNC
ARG NOVNC_PATH=/opt/noVNC

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
    xscreensaver \
    && apt-get remove -y gnome-screensaver  \
    && apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSfL 'https://sourceforge.net/projects/tigervnc/files/stable/1.10.1/tigervnc-1.10.1.x86_64.tar.gz/download' \
    | tar -zxf - -C /usr/local --strip=2 \
    && mkdir -p ${NOVNC_PATH} \
    && curl -sSfL 'https://github.com/novnc/noVNC/archive/v1.2.0.tar.gz' \
    | tar -zxf - -C ${NOVNC_PATH} --strip=1 \
    && chown -R ${NB_USER}:users ${NOVNC_PATH}

# JOVYAN is the default user in jupyter/base-notebook.
# JOVYAN is being set to be passwordless. 
# This allows users to easily wake the desktop when it goes to sleep.
RUN passwd $NB_USER -d
# Get websockify
RUN conda install -y -q websockify=0.12.0
# Pip install the latest version of the integration
USER $NB_USER
RUN curl -s https://api.github.com/repos/mathworks/jupyter-matlab-vnc-proxy/releases/latest | grep tarball_url | cut -d '"' -f 4 | xargs python -m pip install
# Move MATLAB resource files to the expected locations
RUN export RESOURCES_LOC=$(python -c "import jupyter_matlab_vnc_proxy as pkg; print(pkg.__path__[0])")/resources \
    && mkdir -p ${HOME}/.local/share/applications ${HOME}/Desktop ${HOME}/.local/share/ ${HOME}/.icons \
    && cp ${RESOURCES_LOC}/MATLAB.desktop ${HOME}/Desktop/ \
    && cp ${RESOURCES_LOC}/MATLAB.desktop ${HOME}/.local/share/applications\
    && ln -s ${RESOURCES_LOC}/matlab_icon.png ${HOME}/.icons/matlab_icon.png \
    && cp ${RESOURCES_LOC}/matlab_launcher.py ${HOME}/.local/share/ \
    && cp ${RESOURCES_LOC}/mw_lite.html ${NOVNC_PATH} \
    && touch ${HOME}/.Xauthority

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
ENV MW_CONTEXT_TAGS=MATLAB_PROXY:JUPYTER:V1


#####################################################
#####################################################

### Dockerfile build configurations:
# 1. MATLAB from MPM + JMP 
#  docker build -f One.dockerfile -t mifj:mpm .

# 2. MATLAB from MPM + JMP + MEFP
#  docker build -f One.dockerfile -t mifj:mpm --build-arg INSTALL_MATLABENGINE=1 .

# 3. MATLAB from MPM + JMP + VNC
#  docker build -f One.dockerfile -t mifj:mpm --build-arg INSTALL_VNC=1 .

# 4. MATLAB from MPM + JMP + LICENSE_SERVER
#  docker build -f One.dockerfile -t mifj:mpm --build-arg LICENSE_SERVER=port@hostname .

# 5. Mounted MATLAB
#  docker build -f One.dockerfile -t mifj:mpm  MOUNT_MATLAB=1 .

# 5. BYOI MATLAB Image, MATLAB_RELEASE is required to install the right dependencies
#  docker build -f One.dockerfile -t mifj:mpm  MATLAB_IMAGE_NAME=mathworks/matlab:r2024b MATLAB_RELEASE=R2024b .
