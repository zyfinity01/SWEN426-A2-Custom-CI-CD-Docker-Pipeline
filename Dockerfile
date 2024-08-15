FROM ubuntu:24.04
ENV TZ=Pacific/Auckland
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --quiet --assume-yes --no-install-recommends \
        apt-utils=2.7.14build2 \
        tzdata=2024a-3ubuntu1.1 \
        git=1:2.43.0-1ubuntu7.1 \
        ruby=1:3.2~ubuntu1 \
        ruby-dev=1:3.2~ubuntu1 \
        python3=3.12.3-0ubuntu1 \
        python3-pip=24.0+dfsg-1ubuntu1 \
        make=4.3-4.1build2 \
        curl=8.5.0-2ubuntu10.2 \
        ca-certificates=20240203 \
        gnupg=2.4.4-2ubuntu17 \
        build-essential \
        libssl-dev \
        libreadline-dev \
        zlib1g-dev \
        libffi-dev \
        libyaml-dev \
        libgdbm-dev \
        libgdbm-compat-dev \
        libdb-dev \
        libncurses5-dev \
        libtool \
        bison && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install --quiet --assume-yes --no-install-recommends nodejs && \
    pip3 install --no-cache-dir --break-system-packages \
        pre-commit \
        pylint \
        pylint-ignore \
        mpy-cross && \
    apt-get remove --quiet --assume-yes gnupg && \
    apt-get autoremove --quiet --assume-yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Ensure Git safe directory is configured at runtime
ENTRYPOINT ["bash", "-c", "git config --system --add safe.directory '*' && exec \"$@\"", "--"]

CMD ["bash"]
