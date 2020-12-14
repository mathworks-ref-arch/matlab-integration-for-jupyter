# Use MATLAB Integration for Jupyter using VNC in a Docker Container

The `Dockerfile` in this repository builds a Jupyter® Docker® image which contains the `jupyter-matlab-vnc-proxy` package.
This package allows you to connect to a Linux® desktop with MATLAB® installed from your Jupyter environment.

If you want to install the MATLAB Integration for Jupyter using VNC without using Docker, use the installation instructions in the repository
[MATLAB Integration for Jupyter using VNC](https://github.com/mathworks/jupyter-matlab-vnc-proxy) instead.

If you have access to MATLAB R2020b or later, we recommend using the alternative [Use MATLAB Integration for Jupyter in a Docker Container](https://github.com/mathworks-ref-arch/matlab-integration-for-jupyter/tree/main/matlab).
This alternative comes with some limitations (see [Specifications and Limitations](https://www.mathworks.com/products/matlab-online/limitations.html)) but it enables you to open a MATLAB desktop in a web browser tab, directly from your Jupyter environment.

## Requirements

Before starting, make sure you have [Docker](https://docs.docker.com/get-docker/) installed on your system.

## Instructions

The `Dockerfile` in this repository builds upon the base image `jupyter/base-notebook`. Optionally, you can customize the `Dockerfile` to build upon any alternative Jupyter Docker base image.

To build the Docker image, follow these steps:

1. Select a base container image with a MATLAB R2020b or later (64 bit Linux) installation. If you need to create one, follow the steps at [Create a MATLAB Container Image](https://github.com/mathworks-ref-arch/matlab-dockerfile).

2. Open the `Dockerfile`, replace the name `matlab` with the name of the MATLAB image from step 1:

   ```
   FROM matlab AS matlab-install-stage
   ```

3. If MATLAB is not installed at the location `/usr/local/MATLAB` in the image built in step 1, edit the following line to point to you MATLAB installation:

   ```
   COPY --from=matlab-install-stage /usr/local/MATLAB /usr/local/MATLAB
   ```

   For example, if MATLAB is installed at the location `/opt/matlab/R2020a` change the line above to:

   ```
   COPY --from=matlab-install-stage /opt/matlab/R2020a /usr/local/MATLAB
   ```

4. Optionally, to preconfigure a network license manager, open the `Dockerfile`, uncomment the line below, and replace `port@hostname` with the licence server address:

   ```
    # ENV MLM_LICENSE_FILE port@hostname
   ```

5. Build a Docker image labelled `matlab-vnc-notebook`, using the file `Dockerfile`:

   ```bash
   docker build -t matlab-vnc-notebook .
   ```

6. Start a Docker container, and
forward the default Jupyter web-app port (8888) to the host machine:

   ```bash
   docker run -it -p 8888:8888 matlab-vnc-notebook
   ```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter using VNC](https://github.com/mathworks/jupyter-matlab-vnc-proxy).

#### Advanced

Installing MATLAB into the Docker image can make the image very large (greater than 10GB) depending on the MATLAB toolboxes installed.
To make the image smaller, you can give the Docker container access to a MATLAB installation using a volume or bind mount. For more details see [Provide MATLAB as a Volume or Bind Mount](/matlab-vnc/MATLAB_mounted.md).

## Feedback

We encourage you to try this repository with your environment and provide feedback – the technical team is monitoring this repository. If you encounter a technical issue or have an enhancement request, send an email to `jupyter-support@mathworks.com`.


