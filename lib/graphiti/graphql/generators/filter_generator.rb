module Graphiti::GraphQL::Generators
  class FilterGenerator
    def initialize(type_generator, resource, skip_attrs = [])
      @type_generator = type_generator
      @resource = resource
      @skip_attrs = skip_attrs
    end

    def call
      filter_type = @type_generator.add_resource_filter(@resource, @skip_attrs)

      proc do
        argument :filter, filter_type, required: false
      end
    end
  end
end
