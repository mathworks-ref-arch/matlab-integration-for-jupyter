# Provide MATLAB as a Volume or Bind Mount

To provide a MATLAB installation to the container via a volume or bind mount, instead of installing MATLAB inside the image, follow the instructions below.

### Build the Docker Image

Build a Docker image called `matlab-vnc-notebook-nomatlab`, using the file `Dockerfile.mounted`:

```bash
docker build -f Dockerfile.mounted -t matlab-vnc-notebook-nomatlab .
```

### Start the Docker Container

Execute the command below to start a Docker container, bind mount the root directory of your local install of MATLAB `/usr/local/MATLAB/R2020b` into the directory `/usr/local/MATLAB` inside the container, and bind port 8888 on the host to port 8888 of the container (by default, Jupyter's app-server runs on port 8888 inside the container):

```bash
docker run -it -v /usr/local/MATLAB/R2020b:/usr/local/MATLAB:ro -p 8888:8888 matlab-vnc-notebook-nomatlab
```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter using VNC](https://github.com/mathworks/jupyter-matlab-vnc-proxy).
