FROM balenalib/rpi-raspbian:stretch
LABEL maintainer="tuanlm@greenglobal.vn"
LABEL build_date="2019-05-28"
LABEL description="Intel® Distribution of OpenVINO™ Toolkit for Raspberry Pi"


# Update the system and install some dependencies
RUN apt update && apt upgrade -y
RUN apt install -y apt-utils lsb-release dh-autoreconf pkg-config \
   build-essential cmake gfortran
RUN apt install -y --no-install-recommends unzip vim wget curl
RUN apt install -y --no-install-recommends htop geany git


# Install CV2 dependencies
RUN apt install -y --no-install-recommends libjpeg-dev libpng-dev \
   libtiff5-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev \
   libjasper-dev libv4l-dev libxvidcore-dev libx264-dev libgtk2.0-dev \
   libgtk-3-dev libcanberra-gtk* libatlas-base-dev
# RUN apt install -y libcairo2-dev libpango1.0-dev libglib2.0-dev \
#  libgstreamer1.0-0 gstreamer1.0-plugins-base libdrm-dev


# Setup python3 with latest pip package manager
RUN apt install -y --no-install-recommends python3 python3-dev python3-venv
RUN curl -sfL https://bootstrap.pypa.io/get-pip.py | python3 -

#  Install numpy from wheel
RUN python3 -m pip install --index-url='http://pypi.python.org/simple/' numpy


# Get rid of UDEV by rebuilding libusb without UDEV support
# Fix: Conflicts with Kubernetes* and other tools that use orchestration and private networks
ARG LIBUSB_VERSION=1.0.22

RUN apt remove -y libusb-*
RUN cd /tmp/ && \
   wget https://github.com/libusb/libusb/archive/v${LIBUSB_VERSION}.zip && \
   unzip v${LIBUSB_VERSION}.zip && cd libusb-${LIBUSB_VERSION} && \
   ./bootstrap.sh && \
   ./configure --disable-udev --enable-shared && \
   make -j4 && make install && \
   rm -rf /tmp/*


ENV AITL_DIR=/aitl
ENV OPENVINO_DIR="${AITL_DIR}/inference_engine_vpu_arm"

# Copy over OpenVINO installer
COPY ./files/inference_engine_vpu_arm "${OPENVINO_DIR}"

# Correct install location
RUN sed -i "s|<INSTALLDIR>|${OPENVINO_DIR}|" "${OPENVINO_DIR}/bin/setupvars.sh"

# Add setupvars to ~/.bashrc
RUN /bin/bash -c "echo source ${OPENVINO_DIR}/bin/setupvars.sh >> ~/.bashrc"

# Install NCS udev rules
RUN chmod +x "${OPENVINO_DIR}/install_dependencies/install_NCS_udev_rules.sh"
RUN /bin/bash -c "source ${OPENVINO_DIR}/bin/setupvars.sh && \
                ${OPENVINO_DIR}/install_dependencies/install_NCS_udev_rules.sh"


ENV PYTHONPATH="${OPENVINO_DIR}/python/python3.5/armv7l/:${PYTHONPATH}"

WORKDIR ${AITL_DIR}
COPY ./code ./code
CMD ["/bin/bash"]
