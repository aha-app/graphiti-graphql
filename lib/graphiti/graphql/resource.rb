module Graphiti
  module GraphQL
    module Resource
      extend ActiveSupport::Concern

      included do
        class_attribute :_graphql_entry
      end

      class_methods do
        def graphql_entry(value = true)
          self._graphql_entry = value
        end

        def graphql_entry?
          self._graphql_entry
        end

        def graphql_schema
          return @graphql_schema if @graphql_schema

          Dir['app/resources/**/*.rb'].each do |file|
            require_dependency file
          end

          resources = self.descendants.select { |resource| resource.try(:graphql_entry?) }

          @graphql_schema = Graphiti::GraphQL::SchemaBuilder.build do
            resources.each do |klass|
              resource klass.type
            end
          end
        end
      end
    end
  end
end
