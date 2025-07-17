
# MATLAB Integration *for Jupyter* Reference Architecture

To run MATLAB&reg; in Jupyter&reg; inside a container, use the Dockerfile in this repository. The Dockerfile builds an image with [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy) (GitHub), based on a `jupyter/base-notebook:ubuntu-24.04` base image from [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks) (GitHub), which ships with Python 3.12. 

## Build Instructions

### Get Sources
Access this Dockerfile either by directly downloading this repository from GitHub,
or by cloning this repository and
then navigating to the appropriate folder.
```bash
git clone https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter.git
cd matlab-integration-for-jupyter
```
### Build & Run Docker Container
Build the container with a name and tag of your choice.
```bash
docker build -t mifj:R2025a .
```

Run the container.
```bash
docker run -it -p 8888:8888 --rm mifj:R2025a
```

To open JupyterLab, use your browser to visit the address printed in your console of the format `http://<hostname>:8888/?token=<token>`. The `hostname` is the name of the computer running Docker, and the `token` is the secret token printed in the console. 

For more information on running Jupyter images, see [Jupyter Quick Start](https://jupyter-docker-stacks.readthedocs.io/en/latest/index.html#quick-start) (Jupyter Docker Stacks).

## Customize the Image

By default, the [Dockerfile](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/blob/main/Dockerfile) installs MATLAB for the latest available MATLAB release, without any additional toolboxes or products, into the `/opt/matlab` folder, along with the Python package [jupyter-matlab-proxy](https://github.com/mathworks/jupyter-matlab-proxy), which provides the MATLAB Integration for Jupyter.

To customize your build, use the options below.

### Customize MATLAB Release, MATLAB Product List, MATLAB Install Location, License Server and other Python Packages
The [Dockerfile](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/Dockerfile) supports the following Docker build-time variables.

| Argument Name | Description | Default value |
|---|---|---|
| [MATLAB_RELEASE](#build-an-image-for-a-different-release-of-matlab) | The MATLAB release you want to install. | R2025a |
| [MATLAB_PRODUCT_LIST](#build-an-image-with-a-specific-set-of-products) | Products to install as a space-separated list. For more information, see [MPM.md](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md). For example: MATLAB Simulink Deep_Learning_Toolbox Fixed-Point_Designer. | MATLAB |
| [MATLAB_INSTALL_LOCATION](#build-an-image-with-matlab-installed-to-a-specific-location) | The path to install MATLAB. | /opt/matlab |
| [LICENSE_SERVER](#build-an-image-configured-to-use-a-license-server) | The port and hostname of the machine that is running the Network License Manager, using the port@hostname syntax. For example: *27000@MyServerName* | *Unset* |
| [INSTALL_MATLABENGINE](#build-an-image-with-the-matlab-engine-for-python) | Set this value to install the MATLAB Engine for Python into the image. | *Unset* |
| [INSTALL_VNC](#build-an-image-with-the-matlab-integration-for-jupyter-using-vnc) | Set this value to install the [jupyter-matlab-vnc-proxy](https://github.com/mathworks/jupyter-matlab-vnc-proxy), which allows you to connect to a traditional MATLAB desktop via VNC.| *Unset* |

To customize your build, use these arguments with the `docker build` command. See these examples:


#### Build an Image for a Different Release of MATLAB
To build an image for MATLAB R2019b, run:
```bash
docker build --build-arg MATLAB_RELEASE=R2019b -t mifj:R2019b .
```

#### Build an Image with Specific Products
To build an image with MATLAB and Simulink, run:
```bash
docker build --build-arg MATLAB_PRODUCT_LIST='MATLAB Simulink' -t mifj:R2025a .
```

#### Build an Image with MATLAB Installed in a Specific Location
To build an image with MATLAB installed at `/opt/matlab`, use this command.
```bash
docker build --build-arg MATLAB_INSTALL_LOCATION='/opt/matlab' -t mifj:R2025a .
```

#### Build an Image Configured to Use a License Server

If you include the license server information with the `docker build` command, you do not have to provide it when running the container.
```bash
# Build container with the License Server.
docker build --build-arg LICENSE_SERVER=27000@MyServerName -t mifj:R2025a .

# Run the container, without providing license information.
docker run -it --rm -p 8888:8888 mifj:R2025a 
```
Alternatively, to provide the License Server information with `docker run`, you can use the environment variable `MLM_LICENSE_FILE`:
```bash
docker run -it --rm -p 8888:8888 -e MLM_LICENSE_FILE=27000@MyServerName mifj:R2025a
```

For more information on using the Network License Manager, see [Use the Network License Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile?tab=readme-ov-file#use-the-network-license-manager) for more information.

#### Build an Image with the MATLAB Engine for Python
To build the default image along with the MATLAB Engine for Python for a given MATLAB Release, run:
```bash
docker build --build-arg INSTALL_MATLABENGINE=1 --build-arg MATLAB_RELEASE=R2025a -t mifj:R2025a .
```
For more information, see: 
- [MATLAB Engine for Python](https://github.com/mathworks/matlab-engine-for-python) (GitHub).
- [Python Versions Compatible with MATLAB Products](https://mathworks.com/support/requirements/python-compatibility.html) (MathWorks).

##### Note:
* The Dockerfile in this repository an image based on Python 3.11 and the MATLAB Engine for Python only supports this version from MATLAB R2023b onwards.
* If the MATLAB Engine for Python fails to install, this will not fail the `docker build` command.

#### Build an Image with the MATLAB Integration for Jupyter using VNC
To build the default image along with the MATLAB Integration for Jupyter using VNC, run:
```bash
docker build --build-arg INSTALL_VNC=1 -t mifj:R2025a .
```
For more information, see [MATLAB Integration for Jupyter using VNC*(GitHub)*](https://github.com/mathworks/jupyter-matlab-vnc-proxy).

## Installing MATLAB
There are 3 ways to include MATLAB in your container image.
1. Install MATLAB using [MATLAB Package Manager *(mpm)*](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md).
1. [Mount MATLAB on the Image](#mount-matlab-on-the-image).
1. [Bring Your Own Image (BYOI)](#bring-your-own-image)
    * Copy MATLAB installation from another container image.

### Install MATLAB using *mpm*
The default configuration of the Dockerfile uses *mpm* to install MATLAB and the specified toolboxes into the container image as described in the sections above.

### Mount MATLAB on the Image
To provide a MATLAB installation to the container via volume or bind mount, instead of installing MATLAB inside the image, follow the instructions below.

The Dockerfile assumes that you want to mount MATLAB in the `/opt/matlab` folder. Use the Build Argument `MATLAB_INSTALL_LOCATION` to specify a custom location within the container where you want to mount MATLAB. 

#### Build Image
Use the [Dockerfile Build Arguments](https://docs.docker.com/reference/dockerfile/#arg) `MOUNT_MATLAB` and `MATLAB_RELEASE` with your `docker build` command.

```bash
docker build --build-arg MOUNT_MATLAB=1 \
             --build-arg MATLAB_RELEASE=R2025a \
             -t mifj:mounted .
```
The `MATLAB_RELEASE` argument ensures that the system dependencies required for MATLAB are installed in the container.

Note: When you are mounting MATLAB on the container at run time, you cannot install MATLAB Engine for Python at build time.

#### Specify Mount Location at Container Startup
If MATLAB is installed in `/usr/local/MATLAB/R2025a` on your local machine, you can bind mount this folder to `/opt/matlab` using the command shown below:
```bash
docker run -it --rm -v /usr/local/MATLAB/R2025a:/opt/matlab:ro -p 8888:8888 mifj:mounted 
```
For more information, see [Bind Mounts (Docker)](https://docs.docker.com/engine/storage/bind-mounts/).

Access the Jupyter Notebook by following one of the URLs displayed in the output of the docker run command.

This option is useful when you want to minimize the size of the container as installing MATLAB and its toolboxes can make the image large (greater than 10GB), depending on the MATLAB toolboxes installed.

### Bring Your Own Image
To copy an existing MATLAB installation from another container image, specify the image name with the Docker Build Arguments `MATLAB_IMAGE_NAME` and `MATLAB_RELEASE` as shown below:

```bash
# Copies MATLAB from the Dockerhub Image "mathworks/matlab:r2025a" into the image being built.
docker build --build-arg MATLAB_IMAGE_NAME=mathworks/matlab:r2025a \
             --build-arg MATLAB_RELEASE=R2025a \
             -t mifj:copied .
```
The `MATLAB_RELEASE` argument, ensures that the system dependencies required for MATLAB, are installed into the container.

## Pre-Built Images

You can download several Docker images based on this Dockerfile from the GitHub Container Registry.

### jupyter-matlab-notebook
These images are based on `jupyter/base-notebook:ubuntu-24.04` and include:
* MATLAB
* MATLAB Integration for Jupyter
* MATLAB Integration for Jupyter using VNC
* MATLAB Engine for Python 
    * Only available in pre-built images newer than R2023b
    * See [Different Versions of OS or Python](#different-versions-of-os-or-python) for more information on installing the engine for older versions of MATLAB.

**Available Tags**: `R2025a`, `R2024b`, `R2024a`, `R2023b`, `R2023a`, `R2022b`

**Docker Pull Command**:
```bash
# Substitute the tag with your desired version of MATLAB.
docker pull ghcr.io/mathworks-ref-arch/matlab-integration-for-jupyter/jupyter-matlab-notebook:R2025a
```
### jupyter-mounted-matlab-notebook
These images are based on `jupyter/base-notebook:ubuntu-24.04` and include:
* MATLAB Integration for Jupyter
* MATLAB Integration for Jupyter using VNC
* MATLAB Engine for Python 
    * Only available in pre-built images newer than R2023b
    * See [Compatibility for Different Versions of OS or Python](#compatibility-for-different-versions-of-os-or-python) for more information on installing the engine for older versions of MATLAB.

**Available Tags**: `R2025a`, `R2024b`, `R2024a`, `R2023b`, `R2023a`, `R2022b`

**Docker Pull Command**:
```bash
# Substitute the tag with your desired version of MATLAB.
docker pull ghcr.io/mathworks-ref-arch/matlab-integration-for-jupyter/jupyter-mounted-matlab-notebook:R2025a
```
Use the correct version of the image based on the MATLAB release you are mounting on the image.
For example to mount `R2022b` from your local machine, that is installed in `/usr/local/MATLAB/R2022b`, use the following `docker run` command:
```bash
docker run -it --rm -v /usr/local/MATLAB/R2022b:/opt/matlab:ro -p 8888:8888 ghcr.io/mathworks-ref-arch/matlab-integration-for-jupyter/jupyter-mounted-matlab-notebook:R2022b
```

## Compatibility for Different Versions of OS or Python

To build on older versions of Ubuntu or Python, update the base image used in the Dockerfile with the tags specified in the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks?tab=readme-ov-file#using-old-images) repository. 

For example, this page lists `4d70cf8da953` as the tag for an image with `Python 3.10` on `Ubuntu 22.04`.

To build an image with this base layer, update [Line 66 in the Dockerfile](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/blob/main/Dockerfile#L66) to `FROM quay.io/jupyter/base-notebook:4d70cf8da953`.

This might be useful if your workflow depends on older versions of Python. For example the MATLAB Engine for Python only supports Python 3.11 from R2023b. Installing it on MATLAB releases older than R2023b would require an older version of Python, and you can use the approach above to build an image with the desired Python version. For more information about Python compatibility for MATLAB Products, see [Python Versions for MATLAB Products](https://mathworks.com/support/requirements/python-compatibility.html).

### MATLAB Dependencies

To verify that the release of MATLAB you are installing is supported for your operating system, consult the [MATLAB Dependencies](https://github.com/mathworks-ref-arch/container-images/tree/main/matlab-deps) repository.

## Support & Feedback
To submit an enhancement request or request technical support, create an [Issue](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/issues/new).


----

Copyright 2020-2025 The MathWorks, Inc.

----
