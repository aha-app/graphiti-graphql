module Graphiti::GraphQL::Generators
  class TypeGenerator
    attr_reader :schema

    def initialize(schema)
      @type_map = {}
      @resource_map = {}
      @schema = schema
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

      this = self

      object_type = @type_map[type_name] ||= Class.new(::GraphQL::Schema::Object) do
        cattr_accessor :graphiti_resource

        graphql_name type_name.singularize.camelize

        description resource_description

        resource_class.all_attributes.each_pair do |att, details|
          if details[:readable]
            field att, this.field_type(type_name, att, details), null: true, description: details[:description]
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

    def call
      this = self

      @type_map.each_pair do |type_name, type_klass|
        resource = "#{type_name.singularize.classify}Resource".safe_constantize

        type_klass.class_eval do
          resource.sideloads.each_pair do |sideload_name, sideload|
            sideload_proc = SideloadFieldGenerator.new(sideload, this).call

            instance_eval(&sideload_proc)
          end
        end
      end

      this
    end

    def type_for_resource(resource_class)
      @type_map[resource_class.type.to_s]
    end

    def [](type)
      @type_map[type.to_s]
    end

    delegate :field_type, to: :schema
  end
end
