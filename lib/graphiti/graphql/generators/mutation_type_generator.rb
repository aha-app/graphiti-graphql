module Graphiti::GraphQL::Generators
  class MutationTypeGenerator
    def initialize(schema)
      @schema = schema
    end

    def call
      schema = @schema
      generator = self

      @mutation_type ||= Class.new(::GraphQL::Schema::Object) do
        graphql_name "Mutation"

        schema.query_entrypoints.each_pair do |name, details|
          next unless details[:singular]

          resource = details[:resource]

          meta = {
            schema: schema,
            name: name,
            type: schema.type_generator[resource.type],
            resource: resource
          }
          
          field "create_#{name}", mutation: generator.create_mutation(**meta)
          field "update_#{name}", mutation: generator.update_mutation(**meta)
          field "destroy_#{name}", mutation: generator.destroy_mutation(**meta)
        end
      end
    end

    def create_mutation(**meta)
      build_mutation(action: "create", **meta) do |**args|
        model = build_model(args)

        if model.save
          { self.class.graphiti_resource.type.to_s.singularize => model.data }
        else
          { errors: model.errors.to_h }
        end
      end
    end

    def update_mutation(**meta)
      build_mutation(action: "update", **meta) do |**args|
        model = find_model(args)

        if model.update_attributes
          { self.class.graphiti_resource.type.to_s.singularize => model.data }
        else
          { errors: model.errors.to_h }
        end
      end
    end

    def destroy_mutation(**meta)
      build_mutation(action: "destroy", **meta) do |**args|
        model = find_model(args)
        data = model.data

        if model.destroy
          { self.class.graphiti_resource.type.to_s.singularize => data }
        else
          { errors: model.errors.to_h }
        end
      end
    end

    def build_mutation(schema:, name:, type:, resource:, action:, &block)
      mutation = Class.new(::GraphQL::Schema::Mutation) do
        include Graphiti::GraphQL::ParamHelper

        cattr_accessor :graphiti_resource

        graphql_name "#{action.capitalize}#{name.to_s.classify}"

        if %w[update destroy].include?(action)
          argument :id, ::GraphQL::Types::ID, required: true
        end

        if %w[create update].include?(action)
          resource.all_attributes.each_pair do |att, details|
            next if %i[id created_at updated_at].include?(att)
            next unless details[:writable]

            argument att, schema.field_type(name, att, details), required: false
          end
        end

        field name, type, null: true
        field :errors, ::GraphQL::Types::JSON, null: true

        define_method(:resolve, &block)
      end
      mutation.graphiti_resource = resource
      mutation
    end
  end
end
