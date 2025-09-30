#!/usr/bin/env python3
import os
import json

output = {
    "_meta": {
        "hostvars": {
            "SWARM01": {
                "ansible_host": os.environ["SWARM01"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "traefik",
                    "zoonavigator"
                ]
            },
            "SWARM02": {
                "ansible_host": os.environ["SWARM02"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "catalog_indexing_app",
                    "catalog_indexing_postgres",
                    "catalog_indexing_redis",
                    "catalog_indexing_sidekiq"
                ]
            },
            "SWARM03": {
                "ansible_host": os.environ["SWARM03"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "solr-1",
                    "zookeeper-1"
                ]
            },
            "SWARM04": {
                "ansible_host": os.environ["SWARM04"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "solr-2",
                    "zookeeper-2",
                    "solr-3",
                    "zookeeper-3"
                ]
            },
            "SWARM06": {
                "ansible_host": os.environ["SWARM06"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "catalog_find_app",
                    "catalog_find_postgres",
                    "catalog_find_redis",
                    "catalog_find_sidekiq"
                ]
            }
        }
    },
    "all": {
        "children": [
            "docker_engine",
            "docker_swarm_manager",
            "docker_swarm_worker"
        ]
    },
    "docker_engine": {
        "children": [
            "staging"
        ]
    },
    "docker_swarm_manager": {
        "hosts": [
            "SWARM01"
        ]
    },
    "docker_swarm_worker": {
        "hosts": [
            "SWARM02",
            "SWARM03",
            "SWARM04",
            "SWARM06"
        ]
    },
    "staging": {
        "hosts": [
            "SWARM01",
            "SWARM02",
            "SWARM03",
            "SWARM04",
            "SWARM06"
        ]
    }
}

print(json.dumps(output))
