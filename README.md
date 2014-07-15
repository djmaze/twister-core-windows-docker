This Docker image builds [twisterd](https://github.com/miguelfreitas/twister-core) for Windows (32/64 bit) using the MinGW
compiler on Linux. It uses the (almost unmodified) Gitian build scripts from the [twister-core repository](https://github.com/miguelfreitas/twister-core/).

Running the image will copy the compiled files to the `/target` directory inside the container. So you should mount a host directory in
there in order to get them out of the container.

## Quickstart

Use the precompiled image from the Docker index:

    sudo docker pull mazzolino/twister-core-windows-docker
    sudo docker run -v $(pwd):/target mazzolino/twister-core-windows-docker

The output files will be written to the `target` subdirectory of your current folder.

## Building the image yourself

You can build the container yourself. Please be aware that this will
download and compile all dependencies as well, which can take a long
time (> 1h). Building yourself has the advantage that further builds
will make use of Dockerfile caching. So in future builds, only twister itself will be rebuilt:

    sudo docker build -t mazzolino/twister-core-windows-docker .

When the build is done, you can run the image just like the pre-built
one (see Quickstart).
