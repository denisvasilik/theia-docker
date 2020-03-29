#!/bin/bash

set -e

ARCH=$1

echo "Using $ARCH for .NET runtime installation..."

if [ "${ARCH}" == "amd64" ];
then
    curl https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    apt-get update
    apt-get install -y software-properties-common
    apt-get update
    add-apt-repository universe
    apt-get update
    apt-get install -y apt-transport-https
    apt-get update
    apt-get install -y dotnet-runtime-3.1
else
    curl -SL -o dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz
    mkdir -p /usr/share/dotnet
    tar -zxf dotnet.tar.gz -C /usr/share/dotnet
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
    rm dotnet.tar.gz
fi
