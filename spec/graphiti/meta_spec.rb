RSpec.describe Graphiti::GraphQL do
  it "uses resource description in GraphQL object" do
    query = <<~QUERY
      query {
        __type(name: "Employee") {
          name
          description
        }
      }
    QUERY
    expect(query).to respond_with(
      "__type" => {
        "name" => "Employee",
        "description" => "A worker at the company"
      }
    )
  end

  it "uses field description in GraphQL field" do
    query = <<~QUERY
      query {
        __type(name: "Employee") {
          name
          fields {
            name
            description
          }
        }
      }
    QUERY
    response = ApplicationResource.graphql_schema.execute(query).to_h
    fields = response.dig("data", "__type", "fields")
    field = fields.find { |field| field["name"] == "teams" }
    expect(field["description"]).to eq("Teams the employee belongs to")
  end
end
