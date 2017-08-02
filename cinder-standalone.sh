#!/bin/bash

set -eux

# Pin to a known good DLRN repo
export DELOREAN_REPO_URL=${DELOREAN_REPO_URL:-"https://trunk.rdoproject.org/centos7/50/43/50430300b305015505bddf177fedbc15b43332e3_b25059ec"}
# Setting CACHEUPLOAD to 1 will also disable pulling from DLRN current
export CACHEUPLOAD=${CACHEUPLOAD:-"1"}

CURRENT_DIR=$(dirname $0)

sudo setenforce 0
sudo sed -i "s/enforcing/permissive/" /etc/selinux/config

sudo mkdir -p /opt/cinder-standalone
sudo chown -R $USER: /opt/cinder-standalone

sudo yum -y install git

if [ ! -d /opt/cinder-standalone/tripleo-ci ]; then
    git clone https://github.com/openstack-infra/tripleo-ci.git \
        /opt/cinder-standalone/tripleo-ci
fi
# Repository setup
# Only run it if not already done since it is time consuming
if [ ! -f /etc/yum.repos.d/delorean.repo ]; then
    /opt/cinder-standalone/tripleo-ci/scripts/tripleo.sh --repo-setup
fi

# Install initial packages
sudo yum -y install python-tripleoclient docker

# journald must be running for docker
sudo systemctl start systemd-journald
sudo systemctl enable systemd-journald
sudo systemctl start docker
sudo systemctl enable docker

# Symlink all puppet modules
sudo ln -s -f /usr/share/openstack-puppet/modules/* /etc/puppet/modules

# Clone patched puppet-cinder
sudo rm -rf /usr/share/openstack-puppet/modules/cinder
sudo git clone https://github.com/splitwood/puppet-cinder.git /usr/share/openstack-puppet/modules/cinder

# Clone patched tripleo-heat-templates
if [ ! -d /opt/cinder-standalone/tripleo-heat-templates ]; then
    git clone https://github.com/splitwood/tripleo-heat-templates.git \
        /opt/cinder-standalone/tripleo-heat-templates
fi

# Generate docker registry environment
if [ ! -f $HOME/docker_registry.yaml ]; then
        openstack overcloud container image prepare \
            --namespace tripleoupstream \
            --tag latest \
            --images-file overcloud_conatiners.yaml \
            --env-file $HOME/docker_registry.yaml
fi

LOCAL_IP=${LOCAL_IP:-`/usr/sbin/ip -4 route get 8.8.8.8 | awk {'print $7'} | tr -d '\n'`}

EXTRA_ENVS=${EXTRA_ENVS:-""}
if [ -d $HOME/custom-environments ]; then
    for f in $HOME/custom-environments/*; do
        [ -f "$f" ] || continue
        EXTRA_ENVS="$EXTRA_ENVS -e $f";
    done
fi

time sudo openstack undercloud deploy \
    --templates=/opt/cinder-standalone/tripleo-heat-templates \
    --local-ip=$LOCAL_IP \
    --keep-running \
    -e /opt/cinder-standalone/tripleo-heat-templates/environments/services-docker/ironic.yaml \
    -e /opt/cinder-standalone/tripleo-heat-templates/environments/services-docker/mistral.yaml \
    -e /opt/cinder-standalone/tripleo-heat-templates/environments/services-docker/zaqar.yaml \
    -e /opt/cinder-standalone/tripleo-heat-templates/environments/docker.yaml \
    -e /opt/cinder-standalone/tripleo-heat-templates/environments/mongodb-nojournal.yaml \
    -e $HOME/docker_registry.yaml \
    -e $CURRENT_DIR/environments/cinder-standalone.yaml \
    $EXTRA_ENVS
