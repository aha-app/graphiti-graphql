# graphiti-graphql

Automatically generate a GraphQL interface from your [Graphiti](https://www.graphiti.dev) resources. Supports queries (including polymorphic resources), filters, and CRUD mutations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphiti-graphql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphiti-graphql

## Usage

1. Include the gem in your Graphiti `ApplicationResource`.

```ruby
# app/resources/application_resource.rb
class ApplicationResource < Graphiti::Resource
  include Graphiti::Graphql::Resource

  # ...
end
```

2. Add `graphql_entry` to any resources which should be available as a top-level queryable resource in GraphQL.

```ruby
# app/resources/post_resource.rb
class PostResource < ApplicationResource
  graphql_entry

  # ...
end
```

3. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aha-app/graphiti-graphql.

## Credits

The code for this gem was originally based on [wade-tandy/graphiti-graphql](https://github.com/wadetandy/graphiti-graphql).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
