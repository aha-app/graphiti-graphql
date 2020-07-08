module Graphiti::GraphQL::Generators
  class SideloadFieldGenerator
    def initialize(sideload, type_generator)
      @sideload = sideload
      @type_generator = type_generator
      @is_single = sideload.single? || sideload.type.in?([:belongs_to, :polymorphic_belongs_to, :has_one])
      @is_entrypoint = sideload.respond_to?(:query_entrypoint) && sideload.query_entrypoint

      @loader =
        if @is_entrypoint
          Graphiti::GraphQL::BatchLoader::EntrypointLoader
        else
          if @is_single
            case sideload.type
            when :polymorphic_belongs_to then Graphiti::GraphQL::BatchLoader::PolymorphicBelongsToLoader
            when :belongs_to then Graphiti::GraphQL::BatchLoader::BelongsToLoader
            else Graphiti::GraphQL::BatchLoader::SingleItemLoader
            end
          else
            Graphiti::GraphQL::BatchLoader::MultiItemLoader
          end
        end
    end

    def call
      sideload = @sideload
      type_generator = @type_generator
      is_single = @is_single
      is_entrypoint = @is_entrypoint
      loader = @loader

      proc do
        sideload_type = 
          if sideload.polymorphic_parent?
            if sideload.try(:children)
              types = sideload.children.values.map(&:resource_class).map { |resource| type_generator.type_for_resource(resource) }
              Class.new(::GraphQL::Schema::Union) do
                graphql_name sideload.name.to_s.classify
                possible_types *types

                class << self
                  def resolve_type(object, _context)
                    possible_types.find { |type| object.is_a?(type.graphiti_resource.model) }
                  end
                end
              end
            else
              type_generator.type_for_resource(sideload.resource_class)
            end
          else
            type_generator.type_for_resource(sideload.resource_class)
          end
        type_name = is_single ? sideload_type : [sideload_type]

        resolver = Class.new(::GraphQL::Schema::Resolver) do
          cattr_accessor :loader, :sideload, :is_single, :is_entrypoint

          def resolve(**args)
            params = {}
            params[:filter] = args[:filter].to_h if args[:filter]

            loader.for(sideload, params: params, single: is_single).load(is_entrypoint ? :entry : object)
          end
        end

        resolver.loader = loader
        resolver.sideload = sideload
        resolver.is_single = is_single
        resolver.is_entrypoint = is_entrypoint

        field sideload.name, type_name, null: true, resolver: resolver, description: sideload.description do

          if is_single
            argument :id, GraphQL::Types::ID if is_entrypoint
          else
            filter_type = type_generator.add_resource_filter(sideload.resource, [sideload.primary_key, sideload.foreign_key])
            argument :filter, filter_type, required: false
          end
        end
      end
    end
  end
end
