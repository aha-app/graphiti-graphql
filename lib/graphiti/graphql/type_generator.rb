module Graphiti
  module GraphQL
    class TypeGenerator
      GRAPHQL_SCALAR_TYPE_MAP = {
        string: ::GraphQL::Types::String,
        integer_id: ::GraphQL::Types::ID,
        integer: ::GraphQL::Types::Int,
        float: ::GraphQL::Types::Float,
        boolean: ::GraphQL::Types::Boolean,
        datetime: ::GraphQL::Types::ISO8601DateTime,
      }.freeze

      ENTRY_STRUCT = Struct.new(:id).new(:entry)

      def initialize
        @type_map = {}
        @resource_map = {}
      end

      def [](type)
        @type_map[type.to_s]
      end

      def add_resource(resource_class)
        type_name = resource_class.type.to_s

        type_resources = @resource_map[type_name] ||= []
        if type_resources.include?(resource_class)
          return
        else
          type_resources.push(resource_class)
        end

        object_type = @type_map[type_name] ||= Class.new(::GraphQL::Schema::Object) do
          cattr_accessor :graphiti_resource

          graphql_name type_name.singularize.camelize

          description "A #{type_name.singularize}"

          resource_class.all_attributes.each_pair do |att, details|
            if details[:readable]
              # TODO: null
              field att, GRAPHQL_SCALAR_TYPE_MAP[details[:type]], null: false
            end
          end
        end
        object_type.graphiti_resource = resource_class

        resource_class.sideloads.each_value do |sideload|
          if sideload.resource_class.type.blank?
            sideload.children.values.map(&:resource_class).each(&method(:add_resource))
          else
            add_resource(sideload.resource_class)
          end
        end

        object_type
      end

      def finalize
        this = self

        @type_map.each_pair do |type_name, type_klass|
          resource = "#{type_name.singularize.classify}Resource".safe_constantize

          type_klass.class_eval do
            resource.sideloads.each_pair do |sideload_name, sideload|
              instance_eval(&this.field_for_sideload(sideload))
            end
          end
        end
      end

      def type_for_resource(resource_class)
        type_name = resource_class.type.to_s
        @type_map[type_name]
      end

      def field_for_sideload(sideload)
        is_single = sideload.single? || sideload.type.in?([:belongs_to, :polymorphic_belongs_to, :has_one])
        is_entrypoint = sideload.respond_to?(:query_entrypoint) && sideload.query_entrypoint

        loader =
          if is_entrypoint
            BatchLoader::EntrypointLoader
          else
            if is_single
              case sideload.type
              when :polymorphic_belongs_to then BatchLoader::PolymorphicBelongsToLoader
              when :belongs_to then BatchLoader::BelongsToLoader
              else BatchLoader::SingleItemLoader
              end
            else
              BatchLoader::MultiItemLoader
            end
          end

        this = self

        proc do
          sideload_type = 
            if sideload.polymorphic_parent?
              if sideload.try(:children)
                types = sideload.children.values.map(&:resource_class).map { |resource| this.type_for_resource(resource) }
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
                this.type_for_resource(sideload.resource_class)
              end
            else
              this.type_for_resource(sideload.resource_class)
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

          # TODO: null keyword
          field sideload.name, type_name, null: false, resolver: resolver do

            if is_single
              argument :id, GraphQL::Types::ID if is_entrypoint
            else
              sideload.resource.filters.each_pair do |att, details|
                next if att == sideload.primary_key || att == sideload.foreign_key

                # TODO: handle :hash
                next unless TypeGenerator::GRAPHQL_SCALAR_TYPE_MAP.key?(details[:type])

                details[:operators].each do |operator|
                  filter_name = "#{att}_#{operator.first}".to_sym
                  argument filter_name, TypeGenerator::GRAPHQL_SCALAR_TYPE_MAP[details[:type]], required: false
                end
              end
            end
          end
        end
      end
    end
  end
end
