# Use Ubuntu base image
FROM ubuntu:latest

# Set environment to avoid interaction during installation
ENV DEBIAN_FRONTEND=noninteractive

# Create working directory
RUN mkdir -p /ragulsvpn/qrcode

# Set working directory
WORKDIR /ragulsvpn

# Copy the nodejs files
COPY . .

# Update apt and install dependencies
RUN apt-get update && apt-get install -y \
    wireguard-tools \
    iproute2 \
    iptables \
    nodejs \
    npm \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional: Verify node and npm versions
# RUN node -v && npm -v

# Install node.js dependencies
RUN npm install

# Enable IP forwarding
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Expose necessary ports
EXPOSE 51820/udp 3000

# Start the API server
CMD ["node", "index.js"]


## use below command to run ##

# docker run -d \
#  --name ragulsvpn \
#  --cap-add=NET_ADMIN \
#  --cap-add=SYS_MODULE \
#  --device /dev/net/tun \
#  -v /lib/modules:/lib/modules \
#  -e PORT=3000 \
#  -e SERVERIP=<YOUR PUBLIC SERVER IP> \
#  -p 51820:51820/udp \
#  -p 3000:3000 \
#  ragulsvpn:alpha