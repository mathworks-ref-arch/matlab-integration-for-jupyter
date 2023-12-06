# Build with your existing MATLAB Image 

`Dockerfile.byoi` showcases a multi-stage build which extracts MATLAB from an existing image that contains MATLAB.

`Dockerfile.byoi` is based on jupyter/base-notebook:python-{python version number}, which is based on **ubuntu22.04**.

Look in the directory `matlab/ubuntu20.04` for Dockerfiles that are based on `ubuntu20.04`.

Pass the name of your existing MATLAB image to docker build using the `build-time` variable `MATLAB_IMAGE_NAME`.

`Dockerfile.byoi` supports the following build-time variables:
| Argument Name | Default value | Effect |
|---|---|---|
| [MATLAB_RELEASE](#build-an-image-for-a-different-release-of-matlab) | r2023b | The MATLAB release you are using. Used to install its software dependencies.|
| [PYTHON_VERSION](#choose-version-of-python) | 3.10 | Select version of Python used by Jupyter. See [here](https://hub.docker.com/r/jupyter/base-notebook/tags?page=1&name=python-), for list of Python tags available for use. |
| **MATLAB_IMAGE_NAME** | mathworks/matlab:r2023b | Specify the name of the Docker image that MATLAB should be extracted from. |
| [LICENSE_SERVER](#build-an-image-with-license-server-information) | *unset* | The port and hostname of the machine that is running the Network License Manager, using the `port@hostname` syntax. For Example: `27000@MyServerName`. </br> Click [Using the Network License Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile#use-the-network-license-manager) to learn more.|

Listed below is an example of the command to build a Docker image that extracts MATLAB from the image `mathworks/matlab:r2023b` on DockerHub and installs it into `jupyter/base-notebook:python-3.10` with a License Server.
```bash
docker build --build-arg MATLAB_RELEASE=r2023b \
                --build-arg PYTHON_VERSION=3.10 \
                --build-arg MATLAB_IMAGE_NAME=mathworks/matlab:r2023b \
                --build-arg LICENSE_SERVER=12345@hostname.com \
                -t matlab-notebook -f Dockerfile.byoi .
```

Start the container using
```bash
docker run -it --rm -p 8888:8888 matlab-notebook
```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy).
