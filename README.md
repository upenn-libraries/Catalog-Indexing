# Catalog Indexing App

## Docker SolrCloud initialization

Some manual intervention required to set up. You should add this to a startup rake task.
1. Setup basic auth:
`docker exec -it catalog-indexing_solrcloud_1 solr auth enable -credentials catalog:catalog`
2. Zip configset and upload via zookeeper:
`zip -r - solr/conf/* > configset.zip`
`curl -X PUT --header "Content-Type:application/octet-stream" --data-binary @configset.zip "http://localhost:8983/api/cluster/configs/catalog-configset"`
3. Create collections using configset:
`curl -X POST http://localhost:8983/api/collections -H 'Content-Type: application/json' -d '{ "create" { "name": "catalog_dev", "config": "catalog-configset", "numShards": 1 } }'`
`curl -X POST http://localhost:8983/api/collections -H 'Content-Type: application/json' -d '{ "create" { "name": "catalog_test", "config": "catalog-configset", "numShards": 1 } }'`
