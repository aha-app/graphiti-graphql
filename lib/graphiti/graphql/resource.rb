module Graphiti::GraphQL::Resource
  extend ActiveSupport::Concern

  included do
    class_attribute :_graphql_schema
  end

  class_methods do
    def graphql(available: true, entry: true, queryable: true, mutatable: true, relationships: true)
      self._graphql_schema = {
        entry: available && queryable && entry,
        queryable: available && queryable,
        mutatable: available && mutatable,
        relationships: available && relationships
      }
    end

    def graphql_entry?
      _graphql_schema && _graphql_schema[:entry]
    end

    def graphql_queryable?
      _graphql_schema.nil? || _graphql_schema[:queryable]
    end

    def graphql_mutatable?
      _graphql_schema.nil? || _graphql_schema[:mutatable]
    end

    def graphql_relationship?(field)
      return true if _graphql_schema.nil?

      if _graphql_schema[:relationships].is_a?(Array)
        _graphql_schema[:relationships].include?(field)
      else
        _graphql_schema[:relationships]
      end
    end

    def graphql_schema
      return @graphql_schema if @graphql_schema

      Dir['app/resources/**/*.rb'].each do |file|
        require_dependency file
      end

      resources = descendants.select { |resource| resource.try(:graphql_entry?) }

      @graphql_schema = Graphiti::GraphQL::SchemaBuilder.build do
        resources.each do |klass|
          resource klass
        end
      end
    end
  end
end
