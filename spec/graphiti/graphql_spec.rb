RSpec.describe Graphiti::GraphQL do
  it "has a version number" do
    expect(Graphiti::GraphQL::VERSION).not_to be nil
  end

  it "queries employees" do
    Employee.create!(first_name: "Joe", last_name: "Smith")

    query = <<~QUERY
      query {
        employees {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Joe", "lastName" => "Smith" }
      ]
    )
  end
end
