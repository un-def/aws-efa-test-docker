ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# prerequisites

RUN export _CUDA_VERSION=$(echo ${CUDA_VERSION} | awk -F . '{ print $1"-"$2 }') \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        cuda-libraries-dev-${_CUDA_VERSION} \
        cuda-nvcc-${_CUDA_VERSION} \
        libhwloc-dev \
        autoconf \
        automake \
        libtool

# EFA

ARG EFA_VERSION

RUN cd $HOME \
    && curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/aws-efa-installer-${EFA_VERSION}.tar.gz \
    && tar -xf aws-efa-installer-${EFA_VERSION}.tar.gz \
    && cd aws-efa-installer \
    && ./efa_installer.sh -y --skip-kmod -g

ENV PREFIX=/usr/local/
ENV CUDA_PATH=/usr/local/cuda/
ENV LIBFABRIC_PATH=/opt/amazon/efa/
ENV OPEN_MPI_PATH=/opt/amazon/openmpi/
ENV PATH="${LIBFABRIC_PATH}/bin/:${OPEN_MPI_PATH}/bin/:${PATH}"
ENV LD_LIBRARY_PATH="$OPEN_MPI_PATH/lib/:$LD_LIBRARY_PATH"

# NCCL

ARG NCCL_VERSION

RUN cd $HOME \
    && git clone https://github.com/NVIDIA/nccl.git -b v${NCCL_VERSION}-1 \
    && cd nccl \
    && make -j32 src.build BUILDDIR=${PREFIX}

# AWS OFI NCCL

ARG OFI_VERSION

RUN cd $HOME \
    && git clone https://github.com/aws/aws-ofi-nccl.git -b v${OFI_VERSION}-aws \
    && cd aws-ofi-nccl \
    && ./autogen.sh \
    && ./configure \
        --with-cuda=${CUDA_PATH} \
        --with-libfabric=${LIBFABRIC_PATH} \
        --with-mpi=${OPEN_MPI_PATH} \
        --with-cuda=${CUDA_PATH} \
        --with-nccl=${PREFIX} \
        --disable-tests \
        --prefix=${PREFIX} \
    && make -j32 \
    && make install

# NCCL tests

RUN cd $HOME \
    && git clone https://github.com/NVIDIA/nccl-tests \
    && cd nccl-tests \
    && make -j32 \
        MPI=1 \
        MPI_HOME=${OPEN_MPI_PATH} \
        CUDA_HOME=${CUDA_PATH} \
        NCCL_HOME=${PREFIX}
