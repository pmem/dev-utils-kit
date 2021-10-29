# Content

Dockerfiles and scripts placed within this directory are intended to be used as
development process vehicles and part of continuous integration process.

Docker images, found in this repository, serve as a base images
for repositories in [pmem organization](https://github.com/pmem).
For images related to specific project, please see its repository.

Images built out of those recipes may by used with Docker or podman.
In case of any problem, patches and github issues are welcome.

# How to build Docker image

```sh
docker build --build-arg https_proxy=http://proxy.com:port --build-arg http_proxy=http://proxy.com:port -t pmem:fedora-34 -f ./Dockerfile.fedora-34 .
```

# How to use Docker image

To run build and tests on local machine on Docker, execute command like this:

```sh
docker run --network=bridge --shm-size=4G -v /your/workspace/path/:/opt/workspace:z -w /opt/workspace/ -e <env_var>=<value> -e PKG_CONFIG_PATH=/some/pkgconfig/paths -it pmem:fedora-34 /bin/bash
```

To get `strace` working, add to Docker command line:

```sh
 --cap-add SYS_PTRACE
```
