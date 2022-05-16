# Use MATLAB Integration for Jupyter in a Docker Container

The `Dockerfile` in this repository builds a Docker® image based on `jupyter/base-notebook` which contains the `jupyter-matlab-proxy` package and installs MATLAB® using the [MATLAB Package Manager *(mpm)*](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md). 

The resulting Jupyter environment enables you to start MATLAB in a web browser tab from a Jupyter® notebook.

If you want to install the MATLAB Integration for Jupyter without using Docker, use the installation instructions in the repository
[MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy) instead.

## Requirements
* Linux® Operating System
* Docker
* MATLAB version newer than R2020b

## Build Instructions

### Get Sources
 
```bash
# Clone this repository to your machine
git clone https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter.git

# Navigate to the downloaded folder
cd matlab-integration-for-jupyter/matlab
```

### Build & Run Docker Image
```bash
# Build container with a name and tag of your choice.
docker build -t matlab-notebook .
```
Start the container, and forward the default Jupyter web-app port (8888) to the host machine:
```bash
docker run -it --rm -p 8888:8888 matlab-notebook
```

## Customize the Image
The [Dockerfile](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/blob/main/matlab/Dockerfile) supports the following Docker build-time variables:

| Argument Name | Default value | Effect |
|---|---|---|
| [MATLAB_PRODUCT_LIST](#customize-products-to-install) | MATLAB | Specify the list of products to install using product names separated by spaces. Replace spaces within names with underscores. For example: `MATLAB Simulink Deep_Learning_Toolbox Parallel_Computing_Toolbox` </br> See [MPM Documentation](https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md) for more information.|
| [MATLAB_RELEASE](#build-an-image-for-a-different-release-of-matlab) | r2022a | The MATLAB release you want to install. **MUST** be newer than `r2020b` and specified in lower-case|
| [LICENSE_SERVER](#build-an-image-with-license-server-information) | *unset* | The port and hostname of the machine that is running the Network License Manager, using the `port@hostname` syntax. For Example: `27000@MyServerName`. </br> Click [Using the Network License Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile#use-the-network-license-manager) to learn more.|

### Customize Products to Install
The [Dockerfile](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/blob/main/matlab/Dockerfile) defaults to installing MATLAB with no additional toolboxes or products into the `/opt/matlab` folder.

To customize the build, use the Docker [build-time variable](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) `MATLAB_PRODUCT_LIST` to specify the list of products you want to install into the Image.

```bash
docker build --build-arg MATLAB_PRODUCT_LIST="MATLAB Deep_Learning_Toolbox" -t matlab-notebook .
```

### Build an Image for a Different Release of MATLAB
```bash
# Builds an image with MATLAB R2020b
docker build --build-arg MATLAB_RELEASE=r2020b -t matlab-notebook .
```

### Build an Image with License Server Information
Including the license server information with the docker build command avoids having to pass it when running the container.
```bash
# Build container with the License Server
docker build  --build-arg LICENSE_SERVER=27000@MyServerName -t matlab-notebook .
```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy).

## Advanced

* Installing MATLAB into the Docker image can make the image very large (greater than 10GB) depending on the MATLAB toolboxes installed.
To make the image smaller, you can give the Docker container access to a MATLAB installation using a volume or bind mount. For more details see [Provide MATLAB as a Volume or Bind Mount](/matlab/README-mounted.md).

* Use `Dockerfile.byoi` to build an image based on an existing Docker image with MATLAB in it. See [README-byoi.md](/matlab/README-byoi.md)

## Feedback

We encourage you to try this repository with your environment and provide feedback – the technical team is monitoring this repository. If you encounter a technical issue or have an enhancement request, send an email to `jupyter-support@mathworks.com`.