RSpec.describe Graphiti::GraphQL do
  describe "string_enum" do
    it "queries correctly" do
      employee = Employee.create!(first_name: "Joe", last_name: "Smith", group: "engineering")

      query = <<~QUERY
        query {
          employee(id: #{employee.id}) {
            firstName
            lastName
            group
          }
        }
      QUERY

      expect(query).to respond_with(
        "employee" => {
          "firstName" => "Joe",
          "lastName" => "Smith",
          "group" => "engineering"
        }
      )
    end

    it "filters correctly" do
      Employee.create!(first_name: "Joe", last_name: "Smith", group: "engineering")
      Employee.create!(first_name: "Jake", last_name: "Thomas", group: "marketing")

      query = <<~QUERY
        query {
          employees(filter: { group: { eq: marketing } }) {
            firstName
            lastName
            group
          }
        }
      QUERY

      expect(query).to respond_with(
        "employees" => [
          {
            "firstName" => "Jake",
            "lastName" => "Thomas",
            "group" => "marketing"
          }
        ]
      )
    end
  end

  describe "integer_enum" do
    it "queries correctly" do
      employee = Employee.create!(first_name: "Joe", last_name: "Smith", headcount: 100)

      query = <<~QUERY
        query {
          employee(id: #{employee.id}) {
            firstName
            lastName
            headcount
          }
        }
      QUERY

      # TODO: ideally `headcount` should return an integer value
      # but not sure if that is possible in GraphQL.
      expect(query).to respond_with(
        "employee" => {
          "firstName" => "Joe",
          "lastName" => "Smith",
          "headcount" => "100",
        }
      )
    end

    xit "filters correctly" do
      Employee.create!(first_name: "Joe", last_name: "Smith", headcount: 100)
      Employee.create!(first_name: "Jake", last_name: "Thomas", headcount: 1000)

      # TODO: figure out why filtering by a number won't work
      query = <<~QUERY
        query {
          employees(filter: { headcount: { eq: 1000 } }) {
            firstName
            lastName
            headcount
          }
        }
      QUERY

      expect(query).to respond_with(
        "employees" => [
          {
            "firstName" => "Jake",
            "lastName" => "Thomas",
            "headcount" => "1000"
          }
        ]
      )
    end
  end
end
