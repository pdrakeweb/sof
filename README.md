# Server on Fire

Run checks in parallel across multiple servers in a manifest.

## Example

`bin/sof check-server -m ./manifest.yml`

## Adding additional gems

If you need to extend the functionality of "Server on Fire" and want to add additional gems to do so, 
you will have to add it to the Gemfile and run "bundle install --standalone --binstubs bundle/bin/".
This will add the gems code to the bundle/ directory and update the bundle/bundler/setup.rb file