module Graphiti::GraphQL::Generators
  class FieldTypeGenerator
    BASIC_TYPE_MAP = {
      string: ::GraphQL::Types::String,
      integer_id: ::GraphQL::Types::ID,
      uuid: ::GraphQL::Types::ID,
      integer: ::GraphQL::Types::Int,
      float: ::GraphQL::Types::Float,
      big_decimal: ::GraphQL::Types::Float,
      date: ::GraphQL::Types::ISO8601Date,
      datetime: ::GraphQL::Types::ISO8601DateTime,
      string_enum: ::GraphQL::Types::String,
      integer_enum: ::GraphQL::Types::Int,
      boolean: ::GraphQL::Types::Boolean,
      hash: ::GraphQL::Types::JSON,
      array: ::GraphQL::Types::JSON,
    }

    # All types except boolean/hash/array also have an
    # array doppelgänger.
    GRAPHQL_SCALAR_TYPE_MAP = BASIC_TYPE_MAP.keys.reduce(BASIC_TYPE_MAP) do |map, key|
      next map if %i[boolean hash array].include?(key)

      map["array_of_#{key}".to_sym] = [map[:key]]
      map
    end

    def initialize
      @field_types = {}
    end

    def field_type(object, field, details)
      if %i[string_enum integer_enum array_of_string_enum array_of_integer_enum].include?(details[:type])
        # Normalize the object and field names.
        object = object.to_s.singularize.to_sym
        field = field.to_sym

        @field_types[object] ||= {}

        enum_type = @field_types[object][field] ||= Class.new(::GraphQL::Schema::Enum) do
          graphql_name "#{object.to_s.singularize.camelize} #{field}"

          details[:allow].each do |allowed_value|
            value allowed_value, value: allowed_value
          end
        end

        if details[:type].to_s.starts_with?("array_of")
          [enum_type]
        else
          enum_type
        end
      else
        GRAPHQL_SCALAR_TYPE_MAP[details[:type]]
      end
    end

    def argument_type(type)
      GRAPHQL_SCALAR_TYPE_MAP[type]
    end
  end
end
