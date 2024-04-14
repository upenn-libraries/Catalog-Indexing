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
                    "catalog_indexing",
                    "postgres",
                    "redis",
                    "sidekiq"
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
                    "zookeeper-2"
                ]
            },
            "SWARM05": {
                "ansible_host": os.environ["SWARM05"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "solr-3",
                    "zookeeper-3"
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
            "SWARM05"
        ]
    },
    "staging": {
        "hosts": [
            "SWARM01",
            "SWARM02",
            "SWARM03",
            "SWARM04",
            "SWARM05"
        ]
    }
}

print(json.dumps(output))
