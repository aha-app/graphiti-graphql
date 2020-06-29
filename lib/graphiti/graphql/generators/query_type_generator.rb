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
            filter_map = {}

            resource.filters.each_pair do |att, filter_details|
              filter_details[:operators].each do |operator|
                filter_name = "#{att}_#{operator.first}"
                filter_map[filter_name.to_sym] = [att, operator.first]
              end
            end

            resolver = Class.new(::GraphQL::Schema::Resolver) do
              cattr_accessor :filter_map

              def resolve(**args)
                params = {}

                args.each_key do |arg|
                  val = args[arg]
                  params[:filter] ||= {}

                  filter, operator = filter_map[arg]

                  params[:filter][filter] ||= {}
                  params[:filter][filter][operator] = val
                end

                resource = "#{field.name.singularize.classify}Resource".safe_constantize
                resource.all(params).data
              end
            end
            resolver.filter_map = filter_map

            field query_field, [type_info], null: false, resolver: resolver do
              resource.filters.each_pair do |att, filter_details|
                filter_details[:operators].each do |operator|
                  filter_name = "#{att}_#{operator.first}".to_sym
                  argument filter_name, schema.argument_type(filter_details[:type]), required: false
                end
              end
            end
          end
        end
      end
    end
  end
end
