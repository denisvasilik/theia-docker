# Customized Theia Docker Image

This repository is used to create a Docker image that provides a personalized IDE
based on [Eclipse Theia].

[Eclipse Theia]:(https://www.theia-ide.org)


# Install WABT
RUN mkdir -p /home/developer/git && \
    cd /home/developer/git && \
    git clone --recursive https://github.com/WebAssembly/wabt && \
    mkdir -p /home/developer/git/wabt/build && \
    cd  /home/developer/git/wabt/build && \
    cmake .. && \
    cmake --build .