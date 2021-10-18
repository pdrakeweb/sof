# Server on Fire

Run diagnostic checks in parallel across multiple servers in a manifest.

## Usage

### Create a manifest file

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

### Run sof with the manifest

Then run sof with the manifest above

        bin/sof check-server -m ./manifest.yml

## Testing

To run the tests, use rake (or rspec).

### Default (all tests)
        rake

### Specific test suites
        # Unit tests only
        rake spec:unit

        # System tests only
        # Requires SSH agent that allows localhost SSH
        rake spec:system

### Using rspec directly
        # Specific tests
        rspec spec/sof/manifest_spec.rb
