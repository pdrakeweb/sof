# Server on Fire

Run checks in parallel across multiple servers in a manifest.

## Usage

## Create a manifest file

Create a manifest file for the server you want to check. We advise generating 
the file programitcally. 

```yaml
---
servers:
- name: fsdb-1.infra.example.com
  categories:
  - gluster
  - fs
  - mysql_cluster
  - db
port: 22
username: tux
```

In this example we are assigning four categories to the server. Sof when executed
will run all plugins associated with those categories. 

## Run sof with the manifest

Then run sof with the manifest above

        bin/sof check-server -m ./manifest.yml

