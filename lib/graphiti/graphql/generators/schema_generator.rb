module Graphiti::GraphQL::Generators
  class SchemaGenerator
    attr_reader :query_entrypoints, :field_types

    delegate :field_type, to: :field_types
    delegate :argument_type, to: :field_types

    def initialize
      @query_entrypoints = {}
      @field_types = FieldTypeGenerator.new

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

    def call
      root_query = QueryTypeGenerator.new(self).call
      root_mutation = MutationTypeGenerator.new(self).call

      Class.new(::GraphQL::Schema) do
        query(root_query)
        mutation(root_mutation)

        use ::GraphQL::Execution::Interpreter
        use ::GraphQL::Analysis::AST
        use ::GraphQL::Batch
      end
    end

    def type_generator
      return @type_generator if @type_generator

      @type_generator = TypeGenerator.new(self)
      query_entrypoints.each_value do |details|
        @type_generator.add_resource(details[:resource])
      end
      @type_generator.add_sideloads
      @type_generator
    end
  end
end
