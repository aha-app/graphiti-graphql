module Graphiti::GraphQL::BatchLoader
  class BelongsToLoader < SingleItemLoader
    def assign(parent_records, records)
      map = records.group_by(&:id)

      parent_records.each do |parent_record|
        matching = map[parent_record.send(sideload.foreign_key)] || []
        fulfill(parent_record, matching.first)
      end
    end
  end
end
