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

        filter_map = {}

        sideload.resource.filters.each_pair do |att, details|
          next if att == sideload.primary_key || att == sideload.foreign_key

          details[:operators].each do |operator|
            filter_name = "#{att}_#{operator.first}"
            filter_map[filter_name.to_sym] = [att, operator.first]
          end
        end

        resolver = Class.new(::GraphQL::Schema::Resolver) do
          cattr_accessor :loader, :sideload, :is_single, :is_entrypoint, :filter_map

          def resolve(**args)
            params = {}

            args.each_key do |arg|
              val = args[arg]
              params[:filter] ||= {}

              filter, operator = filter_map[arg]

              params[:filter][filter] ||= {}
              params[:filter][filter][operator] = val
            end

            loader.for(sideload, params: params, single: is_single).load(is_entrypoint ? :entry : object)
          end
        end

        resolver.loader = loader
        resolver.sideload = sideload
        resolver.is_single = is_single
        resolver.is_entrypoint = is_entrypoint
        resolver.filter_map = filter_map

        field sideload.name, type_name, null: true, resolver: resolver, description: sideload.description do

          if is_single
            argument :id, GraphQL::Types::ID if is_entrypoint
          else
            sideload.resource.filters.each_pair do |att, details|
              next if att == sideload.primary_key || att == sideload.foreign_key

              filter_type = type_generator.field_type(sideload.parent_resource_class.name, att, details)

              details[:operators].each do |operator|
                filter_name = "#{att}_#{operator.first}".to_sym
                argument filter_name, filter_type, required: false
              end
            end
          end
        end
      end
    end
  end
end
