# Provide MATLAB as a Volume or Bind Mount

To provide a MATLAB installation to the container via a volume or bind mount, instead of installing MATLAB inside the image, follow the instructions below.

`Dockerfile.mounted` is based on jupyter/base-notebook:python-{python version number}, which is based on **ubuntu22.04**.

Look in the directory `matlab/ubuntu20.04` for Dockerfiles that are based on `ubuntu20.04`.

### Build the Docker Image

Build a Docker image called `matlab-notebook-nomatlab`, using the file `Dockerfile.mounted`.

Listed below is an example of the command to build a Docker image that extracts MATLAB from the image `mathworks/matlab:r2023b` on DockerHub and installs it into `jupyter/base-notebook:python-3.10` with a License Server.
```bash
docker build --build-arg MATLAB_RELEASE=r2023b \
                --build-arg PYTHON_VERSION=3.10 \
                --build-arg MATLAB_IMAGE_NAME=mathworks/matlab:r2023b \
                --build-arg LICENSE_SERVER=12345@hostname.com \
                -t  matlab-notebook-nomatlab -f Dockerfile.mounted  .
```

### Start the Docker Container

Execute the command below to start a Docker container, bind mount the directory `/usr/local/MATLAB/R2023b` (which must contain a MATLAB R2023b or later 64 bit Linux installation) into the directory `/opt/matlab` inside the container, and bind port 8888 on the host to port 8888 of the container (by default, Jupyter's app-server runs on port 8888 inside the container):

```bash
docker run -it -v /usr/local/MATLAB/R2023b:/opt/matlab:ro -p 8888:8888 matlab-notebook-nomatlab
```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy).
