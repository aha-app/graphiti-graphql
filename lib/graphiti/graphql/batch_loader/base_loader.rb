module Graphiti::GraphQL::BatchLoader
  class BaseLoader < ::GraphQL::Batch::Loader
    attr_reader :sideload, :params
    def initialize(sideload, context: {}, params: {}, single:)
      @sideload = sideload
      @context = context
      @single = !!single
      @params = params
    end

    def perform(parent_records)
      Graphiti.with_context(@context) do
        query = ::Graphiti::Query.new(sideload.resource, params)
        records = sideload.resolve(parent_records, query, sideload.parent_resource)

        assign(parent_records, records)
      end
    end

    def assign(_parent_records, _records)
      raise NotImplementedError, "Implement in subclass"
    end

    def single?
      @single
    end
  end
end
