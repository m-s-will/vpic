# This Dockerfile creates the base image for running containerized applications
# at Elwetritsch TU KL. 
# The general expectation is that this container and ones layered on top of it
# will be run using Singularity with a cleaned environment and a contained
# file systems (e.g. singularity run -eC container.sif). The Singularity command
# is responsible for binding in the appropriate environment variables,
# directories, and files to make this work.

FROM beelanl/openmpi_2.0.2

SHELL ["/bin/bash", "-l", "-c"]

RUN apt-get update && apt-get upgrade -y && apt-get -y install \
    autoconf \
    git \
    wget \
    curl \
    cmake \
    build-essential \
    python2.7 python-dev \
    freeglut3-dev \
    qt4-dev-tools \
    libpthread-stubs0-dev \
    unzip \
    dos2unix \
    nano \
    libssl-dev python3-dev python3-numpy python3-pip

# We do most of our work in /home/docker. This just
# sets up the base environment in which we can build more sophisticated
# containers
RUN mkdir /home/docker
RUN chmod 777 /home/docker


# needed by mesa
RUN pip install mako

#install mesa
WORKDIR /usr/local
RUN wget mesa.freedesktop.org/archive/older-versions/13.x/13.0.6/mesa-13.0.6.tar.gz && tar xvzf mesa-13.0.6.tar.gz && rm mesa-13.0.6.tar.gz

WORKDIR /usr/local/mesa-13.0.6

RUN autoreconf -fi
RUN ./configure \
    --enable-osmesa\
    --disable-glx \
    --disable-driglx-direct\ 
    --disable-dri\ 
    --disable-egl \
    --with-gallium-drivers=swrast 

RUN make -j 8; make install;


# build glu
ENV C_INCLUDE_PATH '/usr/local/mesa-13.0.6/include'
ENV CPLUS_INCLUDE_PATH '/usr/local/mesa-13.0.6/include'
WORKDIR /usr/local
RUN git clone http://anongit.freedesktop.org/git/mesa/glu.git

WORKDIR /usr/local/glu
RUN ./autogen.sh --enable-osmesa
RUN ./configure --enable-osmesa
RUN make -j 8
RUN make install


# install newer cmake version
RUN cd $HOME; wget https://github.com/Kitware/CMake/releases/download/v3.18.1/cmake-3.18.1.tar.gz; mkdir build; cd build; tar xvfz ../cmake-3.18.1.tar.gz;
RUN cd $HOME/build/cmake-3.18.1/; ./bootstrap; make; make install;


#install paraview
RUN cd /home/docker; mkdir paraview; wget https://www.paraview.org/files/v5.6/ParaView-v5.6.0.tar.gz; tar -zxvf ParaView-v5.6.0.tar.gz -C paraview --strip-components 1;
# Build paraview

RUN cd /home/docker/; mkdir paraview_build; cd paraview_build; \ 
    cmake \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DPARAVIEW_ENABLE_CATALYST=ON  \
    -DPARAVIEW_ENABLE_PYTHON=ON \
    -DPARAVIEW_BUILD_QT_GUI=OFF \
    -DVTK_USE_X=OFF \
    -DOPENGL_INCLUDE_DIR=/usr/local/mesa-13.0.6/include \
    -DOPENGL_gl_LIBRARY=/usr/local/mesa-13.0.6/lib/libOSMesa.so \
    -DVTK_OPENGL_HAS_OSMESA=ON \
    -DOSMESA_INCLUDE_DIR=/usr/local/mesa-13.0.6/include \
    -DOSMESA_LIBRARY=/usr/local/mesa-13.0.6/lib/libOSMesa.so \
    -DPARAVIEW_USE_MPI=ON \
    ../paraview; make -j 8; make install;

ENV ParaView_DIR=""/home/docker/paraview_build""
RUN cp -r /home/docker/paraview_build/lib/ /usr/local/lib/

RUN pip install numpy==1.16.6

# Obtain workload app from GitHub
#RUN git clone https://github.com/lanl/vpic.git /opt/vpic
#RUN pushd /opt/vpic; git checkout 4b9dbb714f1d521fda0af69a29495ebfa5d4634c; popd;
COPY vpic/ /home/docker/vpic

# Build vpic
WORKDIR /home/docker
RUN mkdir vpic.bin; cd vpic.bin; \
    cmake -DUSE_CATALYST=ON \
    -DParaView_DIR=/home/docker/paraview_build/ \
    -DCMAKE_INSTALL_PREFIX=/home/docker/vpic.bin/ \
    ../vpic; make -j;



# Copy launcher scripts
COPY commands.sh /home/docker
COPY entrypoint.sh /home/docker
COPY ompi_launch.sh /home/docker
COPY runvpic.sh /home/docker
COPY vpic_config /home/docker
COPY vpic_config2 /home/docker

RUN dos2unix /home/docker/entrypoint.sh /home/docker/commands.sh /home/docker/ompi_launch.sh /home/docker/runvpic.sh /home/docker/vpic_config /home/docker/vpic_config2
RUN chmod +x /home/docker/entrypoint.sh /home/docker/commands.sh /home/docker/ompi_launch.sh /home/docker/runvpic.sh /home/docker/vpic_config /home/docker/vpic_config2

RUN ./runvpic.sh

EXPOSE 11111

COPY start_simulation.sh /home/docker/threshold
RUN dos2unix /home/docker/threshold/start_simulation.sh
RUN chmod +x /home/docker/threshold/start_simulation.sh
ENTRYPOINT ["/home/docker/paraview_build/bin/pvserver"]

