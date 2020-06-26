module Graphiti
  module GraphQL
    module MutationHelper
      def build_model(args)
        attrs, relationships = jsonapi_params(args)

        self.class.graphiti_resource.build(
          data: {
            type: self.class.graphiti_resource.type,
            attributes: attrs,
            relationships: relationships
          }
        )
      end

      def jsonapi_params(args)
        relationship_keys = self.class.graphiti_resource.sideloads.values.map(&:foreign_key)
        relationship_args = args.slice(*relationship_keys)
        attrs = args.without(*relationship_keys)

        relationships = relationship_args.each_pair.reduce({}) do |acc, (key, value)|
          sideload = self.class.graphiti_resource.sideloads.values.find { |sideload| sideload.foreign_key == key }
          acc[sideload.name] = {
            data: {
              type: sideload.name.to_s.pluralize,
              id: value
            }
          }
          acc
        end

        [attrs, relationships]
      end
    end
  end
end
