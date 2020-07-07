module Graphiti::GraphQL::Generators
  class QueryTypeGenerator
    def initialize(schema)
      @schema = schema
    end

    def call
      schema = @schema

      @query_type ||= Class.new(::GraphQL::Schema::Object) do
        graphql_name "Query"

        schema.query_entrypoints.each_pair do |query_field, details|
          resource = details[:resource]
          singular = details[:singular]
          type_info = schema.type_generator[resource.type]

          if singular
            resolver = Class.new(::GraphQL::Schema::Resolver) do
              def resolve(id:)
                resource = "#{field.name.singularize.classify}Resource".safe_constantize
                resource.find(id: id).data
              end
            end

            field query_field, type_info, null: false, resolver: resolver do
              argument :id, ::GraphQL::Types::ID, required: true
            end
          else
            resolver = Class.new(::GraphQL::Schema::Resolver) do
              def resolve(**args)
                params = {}
                params[:filter] = args[:filter].to_h if args[:filter]

                resource = "#{field.name.singularize.classify}Resource".safe_constantize
                resource.all(params).data
              end
            end

            filters = FilterGenerator.new(schema.type_generator, resource).call

            field query_field, [type_info], null: false, resolver: resolver do
              instance_eval(&filters)
            end
          end
        end
      end
    end
  end
end
