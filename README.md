
# VPIC with Catalyst in Container
This project contains a Dockerfile and all necessary components to create a Docker container for VPIC. 
The container is available on [Dockerhub](https://hub.docker.com/repository/docker/mswill/elwe_vpic), however these versions may not always be up to date.

## Building the container
The Catalyst pipelines can be changed by editing [threshold.py](https://github.com/m-s-will/vpic/blob/main/vpic/sample/threshold.py).
When finished with the customization, the container can be rebuilt by navigating into the source directory and executing:
	
	$ docker build -t <mytag> .

## Running the container
After either pulling or building the container, it can be run by calling:

    $ docker run -p 11111:11111 <mytag>.
    
`-p 11111:11111` makes port 11111 available on the outside which is needed for ParaView. We can then connect to ParaView 5.6.0 by opening `File->Connect...` and adding the server `localhost:11111`. Also, connect Catalyst via `Catalyst->Connect...`. The server is now awaiting Catalyst connections. Finally either execute the workload script provided by `start_simulation.sh` by calling

	$ docker exec -it <containerid> /home/docker/start_simulation.sh
or by executing `bash` in the container and navigating to the executable manually. The container id is printed by the ParaView server when starting the container, the executables paths can be found in `start_simulation.sh`.
