module Graphiti
  module GraphQL
    class MutationGenerator
      GRAPHQL_SCALAR_TYPE_MAP = {
        string: ::GraphQL::Types::String,
        integer_id: ::GraphQL::Types::ID,
        integer: ::GraphQL::Types::Int,
        float: ::GraphQL::Types::Float,
        boolean: ::GraphQL::Types::Boolean,
        date: ::GraphQL::Types::ISO8601Date,
        datetime: ::GraphQL::Types::ISO8601DateTime,
      }.freeze

      class << self
        def create_mutation(name:, type:, resource:)
          mutation = Class.new(GraphQL::Schema::Mutation) do
            include Graphiti::Graphql::MutationHelper

            cattr_accessor :graphiti_resource

            graphql_name "Create#{name.to_s.classify}"

            resource.all_attributes.each_pair do |att, details|
              next if %i[created_at updated_at].include?(att)

              argument att, GRAPHQL_SCALAR_TYPE_MAP[details[:type]], required: false
            end

            field name, type, null: true
            field :errors, GraphQL::Types::JSON, null: true

            def resolve(**args)
              model = build_model(args)

              if model.save
                { self.class.graphiti_resource.type.to_s.singularize => model.data }
              else
                { errors: model.errors.to_h }
              end
            end
          end
          mutation.graphiti_resource = resource
          mutation
        end
      end
    end
  end
end
