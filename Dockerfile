ARG ARCH='amd64'

FROM ${ARCH}/ubuntu:18.04

ARG ARCH='amd64'
ARG THEIA_IDE_VERSION='v1.3.0'

ENV DEBIAN_FRONTEND=noninteractive

# Install NodeJS
RUN apt-get update && \
    apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs

# Install .NET core runtime
COPY resources/install_dotnet.sh install_dotnet.sh
RUN ./install_dotnet.sh ${ARCH}

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt update && apt install yarn

# Install additional packages
RUN apt-get update && \
    apt-get install -y git pkg-config && \
    apt-get update && \
    apt-get install -y python \
                       python-dev \
                       python-pip \
                       libx11-dev \
                       libxkbfile-dev \
                       vim \
                       python3-pip \
                       libpng-dev \
                       iputils-ping \
                       libfreetype6-dev \
                       sudo \
                       unzip \
                       wget \
                       fonts-powerline \
                       apt-transport-https \
                       openjdk-8-jdk && \
    apt-get clean && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Install Python related packages
RUN pip install \
    python-language-server \
    flake8 \
    autopep8 \
    powerline-shell \
    pylint

# User setup
RUN groupadd -g 1000 developer && \
    useradd -u 1000 -g 1000 -ms /bin/bash developer && \
    usermod -a -G sudo developer && \
    usermod -a -G users developer && \
    echo 'developer:developer' | chpasswd

WORKDIR /home/developer

# Add USER to sudoers
COPY resources/sudoers /etc/sudoers
RUN chmod 0440 /etc/sudoers && chown 0:0 /etc/sudoers

# Build Theia IDE
RUN git clone --branch ${THEIA_IDE_VERSION} https://github.com/denisvasilik/theia.git

COPY apps theia/apps
COPY resources/.yarnrc theia/app/.yarnrc
COPY resources/package.json theia/package.json
COPY resources/.yarnrc theia/.yarnrc

RUN cd theia && \
    yarn --cache-folder ./ycache && \
    rm -rf ./ycache

RUN cd theia/apps/ide && \
    yarn --cache-folder ./ycache && \
    yarn theia build ; \
    yarn theia download:plugins && \
    rm -rf ./ycache

USER developer

# Prepare directory structure
RUN mkdir -p .fonts && \
    mkdir -p .theia && \
    mkdir -p workspace

# Add JetBrains Mono and Menlo for Powerline
RUN cd .fonts && \
    wget https://download.jetbrains.com/fonts/JetBrainsMono-1.0.3.zip && \
    unzip JetBrainsMono-1.0.3.zip && \
    rm JetBrainsMono-1.0.3.zip && \
    wget https://github.com/denisvasilik/Menlo-for-Powerline/blob/master/Menlo%20for%20Powerline.ttf && \
    fc-cache -v -f

# Add VS Code related configurations
COPY resources/.theia/settings.json .theia/settings.json

# Activate powerline
COPY resources/.bashrc .bashrc

WORKDIR /home/developer/theia/apps/ide
EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/developer/theia/apps/ide/plugins
ENTRYPOINT [ "yarn", "start", "/home/developer/workspace", "--hostname=0.0.0.0" ]
