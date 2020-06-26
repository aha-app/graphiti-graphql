module Graphiti
  module GraphQL
    class Schema
      GRAPHQL_SCALAR_TYPE_MAP = {
        string: ::GraphQL::Types::String,
        integer_id: ::GraphQL::Types::ID,
        integer: ::GraphQL::Types::Int,
        float: ::GraphQL::Types::Float,
        boolean: ::GraphQL::Types::Boolean,
        date: ::GraphQL::Types::ISO8601Date,
        datetime: ::GraphQL::Types::ISO8601DateTime,
      }.freeze

      attr_reader :query_entrypoints

      def initialize
        @query_entrypoints = {}

        # Anonymous resource class where every supported query is a sideload
        @query_resource = Class.new(Graphiti::Resource) do
          self.adapter = Graphiti::Adapters::Null
          self.type = :query
          self.model = OpenStruct

          attribute :id, :integer_id, readable: false

          def self.name
            'Graphiti::GraphQL::QueryResource'
          end

          def base_scope
            {}
          end

          def resolve(_)
            [OpenStruct.new(id: SecureRandom.uuid)]
          end
        end
      end

      def add_entrypoint(query, resource, singular)
        @query_entrypoints[query.to_sym] = {
          resource: resource,
          singular: singular
        }

        sideload_klass = if singular
          Graphiti::GraphQL::Sideload::SingleEntrypoint
        else
          Graphiti::GraphQL::Sideload::ListEntrypoint
        end

        @query_resource.instance_eval do
          allow_sideload query, class: sideload_klass do
            params { |h| h.delete(:filter) }

            assign do |dummies, results|
              dummies.first.send("#{query}=", results)
            end
          end
        end
      end

      def generate_schema
        root_query = query_type
        root_mutation = mutation_type

        Class.new(::GraphQL::Schema) do
          query(root_query)
          mutation(root_mutation)

          use ::GraphQL::Execution::Interpreter
          use ::GraphQL::Analysis::AST
          use ::GraphQL::Batch
        end
      end

      private

      def type_generator
        return @type_generator if @type_generator

        @type_generator = TypeGenerator.new
        query_entrypoints.each_value do |details|
          @type_generator.add_resource(details[:resource])
        end
        @type_generator.finalize

        @type_generator
      end

      def query_type
        queries = query_entrypoints
        generator = type_generator

        @query_type ||= Class.new(::GraphQL::Schema::Object) do
          graphql_name "Query"

          queries.each_pair do |query_field, details|
            resource = details[:resource]
            singular = details[:singular]
            type_info = generator[resource.type]

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
                    argument filter_name, TypeGenerator::GRAPHQL_SCALAR_TYPE_MAP[filter_details[:type]], required: false
                  end
                end
              end
            end
          end
        end
      end

      def mutation_type
        queries = query_entrypoints
        generator = type_generator

        @mutation_type ||= Class.new(::GraphQL::Schema::Object) do
          graphql_name "Mutation"

          queries.each_pair do |query_field, details|
            next unless details[:singular]

            resource = details[:resource]
            mutation = MutationGenerator.create_mutation(
              name: query_field,
              type: generator[resource.type],
              resource: resource
            )
            field "create_#{query_field}".to_sym, mutation: mutation
          end
        end
      end
    end
  end
end
