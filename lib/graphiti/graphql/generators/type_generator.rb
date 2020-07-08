module Graphiti::GraphQL::Generators
  class TypeGenerator
    attr_reader :schema

    delegate :field_type, to: :schema

    def initialize(schema)
      @schema = schema
      @type_map = {}
      @resource_map = {}
      @type_filter_map = {}
    end

    def add_resource(resource_class)
      type_name = resource_class.type.to_s

      type_resources = @resource_map[type_name] ||= []
      if type_resources.include?(resource_class)
        return
      else
        type_resources.push(resource_class)
      end

      resource_description =
        if resource_class.description
          resource_class.description
        else
          # Default to the name of the resource.
          %w[a e i o u].include?(type_name.downcase[0]) ? "An #{type_name.singularize}" : "A #{type_name.singularize}"
        end

      schema = @schema

      object_type = @type_map[type_name] ||= Class.new(::GraphQL::Schema::Object) do
        cattr_accessor :graphiti_resource

        graphql_name type_name.singularize.camelize

        description resource_description

        resource_class.all_attributes.each_pair do |att, details|
          if details[:readable]
            field att, schema.field_type(type_name, att, details), null: true, description: details[:description]
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

    def add_sideloads
      generator = self

      @type_map.each_pair do |type_name, type_klass|
        resource = "#{type_name.singularize.classify}Resource".safe_constantize

        type_klass.class_eval do
          resource.sideloads.each_pair do |sideload_name, sideload|
            sideload_proc = SideloadFieldGenerator.new(sideload, generator).call

            instance_eval(&sideload_proc)
          end
        end
      end
    end

    def add_resource_filter(resource, skip_attrs = [])
      resource_name = resource.type.to_s.classify
      type_generator = self

      @type_filter_map["#{resource_name}FilterInput"] ||= Class.new(::GraphQL::Schema::InputObject) do
        graphql_name "#{resource_name}FilterInput"

        resource.filters.each_pair do |attribute, filter_details|
          next if skip_attrs.include?(attribute)

          filter_attr_type = Class.new(::GraphQL::Schema::InputObject) do
            graphql_name "#{resource_name}Filter#{attribute.to_s.classify}Input"

            filter_details[:operators].each do |operator|
              argument operator.first, type_generator.field_type(filter_details[:type], attribute, filter_details), required: false
            end
          end

          argument attribute, filter_attr_type, required: false
        end
      end
    end

    def type_for_resource(resource_class)
      @type_map[resource_class.type.to_s]
    end

    def [](type)
      @type_map[type.to_s]
    end
  end
end
