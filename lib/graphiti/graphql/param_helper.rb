module Graphiti::GraphQL::ParamHelper
  def build_model(args)
    self.class.graphiti_resource.build(jsonapi_params(args))
  end

  def find_model(args)
    self.class.graphiti_resource.find(jsonapi_params(args))
  end

  def error_hash(model)
    model.errors.to_h.deep_transform_keys { |key| key.to_s.camelize(:lower) }
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

    {
      data: {
        id: attrs[:id],
        type: self.class.graphiti_resource.type.to_s,
        attributes: attrs,
        relationships: relationships
      }
    }
  end
end
