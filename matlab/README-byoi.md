# Build with your existing MATLAB Image 

`Dockerfile.byoi` showcases a multi-stage build which extracts MATLAB from an existing image that contains MATLAB.

Pass the name of your existing MATLAB image to docker build using the `build-time` variable `MATLAB_IMAGE_NAME`.

`Dockerfile.byoi` supports the following build-time variables:
| Argument Name | Default value | Effect |
|---|---|---|
| **MATLAB_IMAGE_NAME** | mathworks/matlab:r2022a | Specify the name of the Docker image that MATLAB should be extracted from. |
| [MATLAB_RELEASE](#build-an-image-for-a-different-release-of-matlab) | r2022a | The MATLAB release you are using. Used to install its software dependencies.|
| [LICENSE_SERVER](#build-an-image-with-license-server-information) | *unset* | The port and hostname of the machine that is running the Network License Manager, using the `port@hostname` syntax. For Example: `27000@MyServerName`. </br> Click [Using the Network License Manager](https://github.com/mathworks-ref-arch/matlab-dockerfile#use-the-network-license-manager) to learn more.|

To build the Docker image, follow these steps:
```bash
docker build --build-arg MATLAB_RELEASE=r2022a \
              --build-arg MATLAB_IMAGE_NAME=mathworks/matlab \
              --build-arg LICENSE_SERVER=12345@hostname.com \
              -t maltab-notebook -f Dockerfile.byoi .
```
Start the container using
```bash
docker run -it --rm -p 8888:8888 matlab-notebook
```

Access the Jupyter Notebook by following one of the URLs displayed in the output of the ```docker run``` command.
For instructions about how to use the integration, see [MATLAB Integration for Jupyter](https://github.com/mathworks/jupyter-matlab-proxy).
