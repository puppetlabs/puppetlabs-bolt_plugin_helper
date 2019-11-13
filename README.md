# Ruby Plugin Helper

A helper library for [writing Bolt
plugins](https://puppet.com/docs/bolt/latest/writing_plugins.html) in Ruby. It provides a module
which has two methods:
* `required_data` which accepts a template and returns an array of lookups that need to be provided
  by the plugin
* `populate_template` which accepts a template and an array of maps, where each map is the lookups
  and their values for a single target.

Lookups can optional have dot syntax, which can be used to traverse data structures. For example `foo.0.bar` should get the value `baz` from the following structure:
```
{ foo: [ { bar: 'baz' }, { qux: 'corge' } ] }
```

## Setup

To use this library, include this module in a [Puppetfile](https://puppet.com/docs/pe/2019.0/puppetfile.html):

```
mod 'puppetlabs-ruby_plugin_helper'
```

Add it to your [task metadata](https://puppet.com/docs/bolt/latest/writing_tasks.html#concept-677)
```
{
  "files": ["ruby_plugin_helper/files/plugin_helper.rb"],
}
```
## Usage

When writing your plugin, include the module in the plugin class and use the methods provided to
populate templated data that users may define in their inventory when using your plugin.

### required_data

This method accepts a template from the Bolt inventory file, which should look approximately like:
```
{ name: 'lookup',
  uri: 'look.0.uri',
  config: {
    ssh: {
      user: 'user.lookup'
    }
  }
}
```

And returns an array of arrays, where each array is the lookup to be made:
```
[['lookup'], ['look', '0', 'uri'], ['user', 'lookup']]
```
Note that integers remain strings, and must be converted to array indices by the plugin itself.

### apply_mapping

This method accepts a template and a single map of lookup keys to their values (i.e. a lookup for a
target). It's...hard to describe in words:

Template:
```
{ name: 'lookup',
  uri: 'look.0.uri',
  config: {
    ssh: {
      user: 'user.lookup'
    }
  }
}
```

Lookups:
```
{ 'lookup' => 'Target 1',
  'look' => [ { 'uri' => 'hostname.com' } ],
  'user' => { 'lookup' => 'AcidBurn' }
}
```

Return:
```
{ name: 'Target 1',
  uri: 'hostname.com',
  config: {
    ssh: {
      user: 'AcidBurn'
    }
  }
}
```

This will often be mapped over an array of records, like so:

```
lookups = [
  { 'lookup' => 'Target 1',
    'look' => [ { 'uri' => 'kate.com' } ],
    'user' => { 'lookup' => 'AcidBurn' }
  },
  { 'lookup' => 'Target 2',
    'look' => [ { 'uri' => 'dade.com' } ],
    'user' => { 'lookup' => 'CrashOverride' }
  }
]

lookups.map { |lookup| apply_mapping(template, lookup) }
```


## Examples

It's best to use live examples from the [aws_inventory
plugin](https://github.com/puppetlabs/puppetlabs-aws_inventory/), though this is a simplified
illustration of using the helper:

```ruby
def resolve_reference(plugin_config)
  template = plugin_config.delete(:target_mapping)
  client = config_client(plugin_config)
  targets = request_targets(client)
  
  # This gets the lookup values that the plugin needs to 'fill in'
  lookups = required_data(template)
  target_data = targets.map do |target|
    attributes.each_with_object({}) do |attr, acc|
      attr = attr.first
      acc[attr] = target.respond_to?(attr) ? target.send(attr) : nil
    end
  end 

  # Returns data structure to be sent to the inventory
  target_data.map { |data| apply_mapping(template, data) }
end
```
