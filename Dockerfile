FROM ubuntu:latest

SHELL ["/bin/bash", "-c"]

RUN apt update && apt install -y curl gnupg lsb-release
# Add ROS 2 GPG key and repository for colcon
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add - \
    && echo "deb [arch=amd64] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list

# Install git
RUN apt update \
    && apt install -y --no-install-recommends \
        cmake g++ python3-pip wget git \
        python3-colcon-common-extensions \
        libyaml-cpp-dev libboost-program-options-dev \
        libcurlpp-dev libasio-dev libcurl4-openssl-dev \
        libssl-dev libwebsocketpp-dev \
        libtinyxml2-dev libboost-system-dev \
        build-essential

# Install Fast-DDS from source
RUN mkdir -p ./Fast-DDS/src && cd ./Fast-DDS/src \
    # Clone Repos
    && git clone https://github.com/eProsima/foonathan_memory_vendor.git \
    && git clone https://github.com/eProsima/Fast-CDR.git fastcdr \
    && git clone https://github.com/eProsima/Fast-DDS.git fastdds \
    # Build using colcon
    && cd .. \
    && colcon build --packages-up-to fastdds

# Install Fast-DDS-Gen from source
#RUN apt install openjdk-11-jdk -y && \
#    cd /Fast-DDS/src && \
#    git clone --recursive https://github.com/eProsima/Fast-DDS-Gen.git fastddsgen && \
#    cd fastddsgen && \
#    ./gradlew assemble

# Install Integration Service from source
RUN mkdir -p ./is-workspace/src && cd ./is-workspace/src && \
    git clone --recursive https://github.com/eProsima/Integration-Service.git && \
    git clone https://github.com/eProsima/FastDDS-SH.git && \
    git clone https://github.com/eProsima/WebSocket-SH.git

# Install GCC 11 and set as default
RUN apt-get update && apt-get install -y g++-11 gcc-11 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100

# Build IS
RUN cd ./is-workspace && \
    colcon build && \
    source install/setup.bash

ENTRYPOINT ["/bin/bash", "-lc", "source ./is-workspace/install/setup.bash; exec /bin/bash"]

EXPOSE 80