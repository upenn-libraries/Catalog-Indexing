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

The `staging` Find environment uses the `catalog-staging` collection alias, and the `production` Find environment uses the `catalog-production` collection alias. To change the destination collection for these aliases, use the Solr admin UI ("Collections" -> "Create alias") for the target environment and overwrite the existing alias with the new destination collection. The change will be immediate.

When swapping alias destinations, don't forget that you may also want to make a corresponding change your Webhook and Ad Hoc indexing collection targets in the applications `Settings` UI.

## Development

The development environment uses Taskfile and Docker. `task up` starts a Docker-in-Docker container (`catalog-indexing`, on `172.16.12.0/24`, Docker API on `127.0.0.1:2392`) and runs the Ansible playbook inside it against a single-node Docker Swarm. The repository is mounted at `/home/app` in that container, and the Rails app at `/home/app/rails_app` is bind-mounted into the app and Sidekiq services.

### Requirements

1. Install [Task](https://taskfile.dev/) (`go-task`):
   - **Linux:** Follow the [Task installation instructions](https://taskfile.dev/docs/installation) for your package manager.
   - **macOS:** `brew install go-task`

2. Install Docker:
   - **macOS:** [Install Docker Desktop](https://docs.docker.com/desktop/install/mac-install/).
     You should also request access to the Penn Libraries Docker Team license via [IT Helpdesk](https://ithelp.library.upenn.edu/support/home) for full functionality.
   - **Linux:** [Install Docker Engine](https://docs.docker.com/engine/install/).

### Starting the environment

From the `.dev` directory run:

```bash
task up
```

On first run, Task fetches the remote taskfiles and asks for confirmation (`Y`). During startup you may be prompted for your local machine password (to add `catalog-indexing-dev.library.upenn.edu` and `catalog-indexing-dev.library.upenn.int` to `/etc/hosts`) and your LDAP credentials (to read secrets from HashiCorp Vault).

When provisioning finishes, the app is at [https://catalog-indexing-dev.library.upenn.edu](https://catalog-indexing-dev.library.upenn.edu) and the Solr admin at [http://catalog-indexing-dev.library.upenn.int/solr1/#/](http://catalog-indexing-dev.library.upenn.int/solr1/#/).

### Stopping and removing

From the `.dev` directory, `task down` stops and removes the environment and keeps its data volume; `task purge` also removes the volume.

### Docker context

When the environment is running, switch the Docker context to it with `task docker:context:use:app`; local `docker` commands then run against the development swarm. Switch back with `task docker:context:use:default`.

#### Rails Application
For information about the Rails application, see the [README](rails_app/README.md) in the Rails application root. This includes information about running the test suite, performing indexing operations, development styleguide and general application information.
