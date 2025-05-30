# Dockerfile for the Jenkins Docker Agent

# Using a specific version of Ubuntu is recommended for reproducible builds
FROM ubuntu:22.04

# Update package lists and install OpenSSH server and sudo
RUN apt-get update && apt-get install --no-install-recommends -y \
    openssh-server \
    sudo \
    default-jdk \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Create a non-root user 'jenkins' for running agent tasks
# -rm: remove home directory if it exists
# -d /home/ubuntu: set home directory (note: image uses /home/ubuntu, consider /home/jenkins for consistency)
# -s /bin/bash: set default shell
# -g root: set primary group to root
# -G sudo: add to sudo group
# -u 1000: set user ID
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 jenkins

# Set password for the 'jenkins' user (consider using SSH keys for better security in production)
RUN echo 'jenkins:jenkins' | chpasswd

# Ensure the SSH service is started
# Note: For production, consider using an entrypoint script to manage services
RUN service ssh start

# Expose port 22 for SSH connections
EXPOSE 22

# Set the working directory for the agent
WORKDIR /home/ubuntu

