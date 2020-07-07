RSpec.describe Graphiti::GraphQL do
  it "filters top-level employees by name" do
    Employee.create!(first_name: "Joe", last_name: "Smith")
    Employee.create!(first_name: "Joe", last_name: "Thomas")
    Employee.create!(first_name: "Jack", last_name: "Thomas")

    query = <<~QUERY
      query {
        employees(filter: { firstName: { eq: "Joe" } }) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Joe", "lastName" => "Smith" },
        { "firstName" => "Joe", "lastName" => "Thomas" }
      ]
    )
  end

  it "filters nested positions by title" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    department1 = Department.create!(name: "Paper Management")
    Position.create!(department: department1, employee: employee, title: "Assistant to Regional Manager")
    department2 = Department.create!(name: "Pencil Pushing")
    Position.create!(department: department2, employee: employee, title: "Regional Manager")

    query = <<~QUERY
      query {
        employees {
          firstName
          lastName
          positions(filter: { title: { eq: "Assistant to Regional Manager" } }) {
            title
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        {
          "firstName" => "Joe",
          "lastName" => "Smith",
          "positions" => [
            {
              "title" => "Assistant to Regional Manager"
            }
          ]
        }
      ]
    )
  end
end
