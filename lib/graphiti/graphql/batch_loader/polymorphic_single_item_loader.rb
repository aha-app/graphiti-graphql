module Graphiti::Graphql::BatchLoader
  class PolymorphicSingleItemLoader < BaseLoader
    def assign(parent_records, records)
      map = records.reduce({}) do |acc, (polymorphic_type, records)|
        acc[polymorphic_type] = records.group_by(&sideload.foreign_key)
        acc
      end

      parent_records.each do |parent_record|
        polymorphic_type = parent_record["#{sideload.name}_type"]
        polymorphic_id = parent_record.send(sideload.foreign_key)
        matching = map[polymorphic_type][polymorphic_id] || []
        fulfill(parent_record, matching.first&.send(sideload.name))
      end
    end
  end
end
