FROM ubuntu:focal AS builder

RUN apt update ; DEBIAN_FRONTEND=noninteractive apt install libssl-dev libyaml-dev libncurses-dev libc-ares-dev libprotobuf-dev protobuf-compiler libjq-dev libyaml-cpp-dev libgrpc++-dev protobuf-compiler-grpc rpm libelf-dev cmake build-essential libcurl4-openssl-dev linux-headers-generic clang llvm git pkg-config -y ; apt-get clean

WORKDIR /code
COPY . .

WORKDIR /code/build

RUN cmake -DBUILD_BPF=On -DUSE_BUNDLED_DEPS=ON -DCMAKE_INSTALL_PREFIX=/usr DCMAKE_BUILD_TYPE=release ..

RUN sed -i -e '/RING_BUF_SIZE/s/8/64/' sysdig-repo/sysdig-prefix/src/sysdig/driver/ppm_ringbuffer.h && \
    sed -i -e '/RING_BUF_SIZE/s/8/64/' driver/src/ppm_ringbuffer.h

RUN KERNELDIR=/lib/modules/$(ls /lib/modules)/build make -j4 all && \
    KERNELDIR=/lib/modules/$(ls /lib/modules)/build make package


FROM ubuntu:focal

LABEL maintainer="cncf-falco-dev@lists.cncf.io"

LABEL usage="docker run -i -t -v /var/run/docker.sock:/host/var/run/docker.sock -v /dev:/host/dev -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro --name NAME IMAGE"

ARG FALCO_VERSION=latest
ARG VERSION_BUCKET=deb
ENV VERSION_BUCKET=${VERSION_BUCKET}

ENV FALCO_VERSION=${FALCO_VERSION}
ENV HOST_ROOT /host
ENV HOME /root

RUN cp /etc/skel/.bashrc /root && cp /etc/skel/.profile /root

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	bash-completion \
	bc \
	clang-7 \
	ca-certificates \
	curl \
	dkms \
	gnupg2 \
	gcc \
	jq \
	libc6-dev \
	libelf-dev \
	libmpx2 \
	llvm-7 \
	netcat \
	xz-utils \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder /code/build/falco*.deb /tmp
RUN dpkg -i /tmp/falco*.deb ; rm -rf /tmp/falco*.deb

# Change the falco config within the container to enable ISO 8601
# output.
RUN sed -e 's/time_format_iso_8601: false/time_format_iso_8601: true/' < /etc/falco/falco.yaml > /etc/falco/falco.yaml.new \
	&& mv /etc/falco/falco.yaml.new /etc/falco/falco.yaml

# Some base images have an empty /lib/modules by default
# If it's not empty, docker build will fail instead of
# silently overwriting the existing directory
RUN rm -df /lib/modules \
	&& ln -s $HOST_ROOT/lib/modules /lib/modules

COPY ./docker/falco/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/falco"]
