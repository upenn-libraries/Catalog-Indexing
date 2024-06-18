# Catalog Indexing Environment

This environment manages the services surrounding the creation and maintenence of the Solr index that powers the Penn Libraries catalog. This includes:
1. Solr infrastructure and configuration for a SolrCloud holding indexed catalog information
2. A Rails app for managing the building and maintenance of those indexes
3. Sidekiq workers that manage the different indexing jobs enqueued by the Rails app

## Managing Solr configuration in deployed environments

### Configset changes

Our GitLab deployment pipelines push changes to the configset included here to the SolrCloud via the Zookeeper CLI. In order for changes to take effect in any collections using the configset, a RELOAD must be issued. This can be most easily accomplished through the Solr admin UI ("Collections" -> your collection -> "Reload" button), but can also be done via [an API call](https://solr.apache.org/guide/solr/latest/deployment-guide/collection-management.html#reload).

### Collection Alias changes

Our full index processing creates a new Solr collection on each run. This allows the collections to be swapped in sync with front-end changes or as needs otherwise dictate.

The `staging` Find environment uses the `catalog-staging` collection alias, and the `production` Find environment uses the `catalog-production` collection alias. To change the destination collection for these aliases, use the Solr admin UI ("Collections" -> "Create alias") and overwrite the existing alias with the new destination collection. The change will be immediate.

When swapping alias destinations, don't forget that you may also want to make a corresponding change your Webhook and Ad Hoc indexing collection targets in the applications `Settings` UI.

## Development

> Caveat: The vagrant development environment has only been tested in the local environments our developers currently have. This currently includes Linux, Intel-based Macs and M1 Macs.

In order to use the integrated development environment you will need to install [Vagrant](https://www.vagrantup.com/docs/installation) [do *not* use the Vagrant version that may be available for your distro repository - explicitly follow instructions at the Vagrant homepage] and the appropriate virtualization software. If you are running Linux or Mac x86 then install [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads), if you are using a Mac with ARM processors then install [Parallels](https://www.parallels.com/).

You may need to update the VirtualBox configuration for the creation of a host-only network. This can be done by creating a file `/etc/vbox/networks.conf` containing:

```
* 10.0.0.0/8
```

#### Starting

From the [vagrant](vagrant) directory run:

if running with Virtualbox:
```
vagrant up --provision
```

if running with Parallels:
```
vagrant up --provider=parallels --provision
```

This will run the [vagrant/Vagrantfile](vagrant/Vagrantfile) which will bring up an Ubuntu VM and run the Ansible script which will provision a single node Docker Swarm behind nginx with a self-signed certificate to mimic a load balancer. Your hosts file will be modified; the domain `catalog-indexing-dev.library.upenn.edu` will be added and mapped to the Ubuntu VM. Once the Ansible script has completed and the Docker Swarm is deployed you can access the application by navigating to [https://catalog-indexing-dev.library.upenn.edu](https://catalog-indexing-dev.library.upenn.edu).

#### Stopping

To stop the development environment, from the `vagrant` directory run:

```
vagrant halt
```

#### Destroying

To destroy the development environment, from the `vagrant` directory run:

```
vagrant destroy -f
```

#### SSH

You may ssh into the Vagrant VM by running:

```
vagrant ssh
```

#### Rails Application
For information about the Rails application, see the [README](rails_app/README.md) in the Rails application root. This includes information about running the test suite, performing indexing operations, development styleguide and general application information.
