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
                    "solr-2",
                    "solr-3",
                    "zookeeper-1"
                ]
            },
            "SWARM04": {
                "ansible_host": os.environ["SWARM04"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "solr-4",
                    "solr-5",
                    "solr-6",
                    "zookeeper-2"
                ]
            },
            "SWARM05": {
                "ansible_host": os.environ["SWARM05"],
                "ansible_python_interpreter": "/usr/bin/python3",
                "swarm_labels": [
                    "solr-7",
                    "solr-8",
                    "solr-9",
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
            "production"
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
    "production": {
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
