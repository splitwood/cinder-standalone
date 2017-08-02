Installing
==========

This has been tested on CentOS 7 x86_64.

Use a non-root user with sudo access.

Clone this repository::

    git clone https://github.com/splitwood/cinder-standalone.git

Run the installation script::

    cinder-standalone/cinder-standalone.sh

There will be a significant amount of output. When successful, the following
can be seen towards the end of the output when the command has stopped
running::

    Deploy Successful.
    Log files at: /tmp/undercloud_deploy-tDYL5h
    Log files at: /tmp/undercloud_deploy-tDYL5h

If it succeeds, it will result in the following conatiners running under
docker::

		[jslagle@cinder-standalone ~]# sudo docker ps
		CONTAINER ID        IMAGE                                                   COMMAND             CREATED              STATUS              PORTS               NAMES
		3496ffd0a7bc        tripleoupstream/centos-binary-cinder-api:latest         "kolla_start"       8 seconds ago        Up 6 seconds                            cinder_api_cron
		5f4836d1cb66        tripleoupstream/centos-binary-cinder-volume:latest      "kolla_start"       8 seconds ago        Up 7 seconds                            cinder_volume
		85bbbe227bb5        tripleoupstream/centos-binary-cinder-api:latest         "kolla_start"       9 seconds ago        Up 8 seconds                            cinder_api
		9dd63f664982        tripleoupstream/centos-binary-cinder-scheduler:latest   "kolla_start"       9 seconds ago        Up 8 seconds                            cinder_scheduler
		d65dbb82dc97        tripleoupstream/centos-binary-iscsid:latest             "kolla_start"       26 seconds ago       Up 24 seconds                           iscsid
		eef11f0637a0        tripleoupstream/centos-binary-mariadb:latest            "kolla_start"       About a minute ago   Up About a minute                       mysql
		8231c1c3b416        tripleoupstream/centos-binary-rabbitmq:latest           "kolla_start"       2 minutes ago        Up 2 minutes                            rabbitmq
		93fc4b7901e4        tripleoupstream/centos-binary-heat-all                  "heat-all"          6 minutes ago        Up 6 minutes                            heat_all

Using Cinder
============

By default, the LVM driver is configured. cinderclient can be used as shown to
communicate with Cinder. Replace the IP address with the actual IP address in
the environment.

List volumes::

    cinder \
      --os-user-id userid \
			--os-project-id projectid \
      --os-auth-type noauth \
      --os-endpoint \
      http://192.168.122.185:8776/v2 \
      list

Create a volume::

    cinder \
      --os-user-id userid \
			--os-project-id projectid \
      --os-auth-type noauth \
      --os-endpoint \
      http://192.168.122.185:8776/v2 \
      create 1

Show the volume in LVM::

    sudo lvs
