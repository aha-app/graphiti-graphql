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
          next unless resource.graphql_queryable?

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

                if args[:sort]
                  sort_str = args[:sort].to_h.each_pair.reduce([]) do |sort, (field, dir)|
                    sort + [dir == "DESC" ? "-#{field}" : field.to_s]
                  end
                  params[:sort] = sort_str.join(",")
                end

                resource = "#{field.name.singularize.classify}Resource".safe_constantize
                resource.all(params).data
              end
            end

            filter_type = schema.type_generator.add_resource_filter(resource)
            sort_type = schema.type_generator.add_resource_sort(resource)
            field query_field, [type_info], null: false, resolver: resolver do
              argument :filter, filter_type, required: false
              argument :sort, sort_type, required: false
            end
          end
        end
      end
    end
  end
end
