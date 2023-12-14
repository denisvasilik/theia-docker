ARG NODE_VERSION=18.17.0

FROM node:${NODE_VERSION}
RUN apt-get update && apt-get install -y libsecret-1-dev
ARG version=latest
WORKDIR /home/theia
ADD $version.package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

FROM amd64/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=18

# Install NodeJS
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | \
    tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install nodejs -y

# Install .NET core runtime
COPY resources/install_dotnet.sh install_dotnet.sh
RUN ./install_dotnet.sh ${ARCH}

# Install additional packages
RUN apt-get update && \
    apt-get install -y git pkg-config && \
    apt-get update && \
    apt-get install -y python3 \
                       python3-pip \
                       libx11-dev \
                       libxkbfile-dev \
                       libsecret-1-0 \
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
                       openjdk-8-jdk \
                       cmake && \
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
    echo 'developer:developer' | chpasswd && \
    chown developer:developer /home/developer -R

WORKDIR /home/developer

# Add USER to sudoers
COPY resources/sudoers /etc/sudoers
RUN chmod 0440 /etc/sudoers && chown 0:0 /etc/sudoers

COPY resources/.bashrc /root/.bashrc
RUN echo 'export PATH="$PATH:/home/developer/.cargo/bin"' >> /root/.profile

USER developer

# Install Rust
RUN curl https://sh.rustup.rs -o install_rustup.sh && \
    chmod +x install_rustup.sh && \
    ./install_rustup.sh -y && \
    . .cargo/env && \
    rustup toolchain install stable-x86_64-unknown-linux-gnu && \
    rustup default stable-x86_64-unknown-linux-gnu && \
    .cargo/bin/rustup component add rust-analysis --toolchain stable-x86_64-unknown-linux-gnu && \
    .cargo/bin/rustup component add rust-src --toolchain stable-x86_64-unknown-linux-gnu && \
    .cargo/bin/rustup component add rls --toolchain stable-x86_64-unknown-linux-gnu

# Prepare directory structure
RUN mkdir -p .fonts && \
    mkdir -p .theia && \
    mkdir -p git

# Add JetBrains Mono
RUN cd .fonts && \
    wget https://download.jetbrains.com/fonts/JetBrainsMono-1.0.3.zip && \
    unzip JetBrainsMono-1.0.3.zip && \
    rm JetBrainsMono-1.0.3.zip && \
    fc-cache -v -f

# Add VS Code related configurations
COPY resources/.theia/settings.json .theia/settings.json

# Activate powerline
COPY resources/.bashrc .bashrc

ENV HOME /home/developer
WORKDIR /home/developer
COPY --from=0 /home/theia /home/developer
EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/developer/plugins
ENV USE_LOCAL_GIT true
# node /home/developer/src-gen/backend/main.js /home/git --hostname=0.0.0.0
ENTRYPOINT [ "node", "/home/developer/src-gen/backend/main.js", "/home/git", "--hostname=0.0.0.0" ]
