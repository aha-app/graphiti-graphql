module Graphiti::GraphQL::Sideload
  class ListEntrypoint < Graphiti::Sideload::HasMany
    def query_entrypoint
      true
    end
  end
end
