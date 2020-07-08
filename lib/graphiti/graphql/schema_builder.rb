module Graphiti::GraphQL
  class SchemaBuilder
    def self.build(&block)
      new.build(&block).call
    end

    def build(&block)
      @schema = Generators::SchemaGenerator.new
      instance_eval(&block)
      @schema.tap do
        @schema = nil
      end
    end

    def resource(resource_class)
      name = resource_class.type.to_s

      @schema.add_entrypoint(name.singularize, resource_class, true)
      @schema.add_entrypoint(name.pluralize, resource_class, false)
    end
  end
end
