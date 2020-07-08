RSpec.describe Graphiti::GraphQL do
  it "sorts top-level employees by name" do
    Employee.create!(first_name: "Joe", last_name: "Smith")
    Employee.create!(first_name: "Adam", last_name: "Thomas")
    Employee.create!(first_name: "Sam", last_name: "Jeffrey")

    query = <<~QUERY
      query {
        employees(sort: { firstName: ASC }) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Adam", "lastName" => "Thomas" },
        { "firstName" => "Joe", "lastName" => "Smith" },
        { "firstName" => "Sam", "lastName" => "Jeffrey" },
      ]
    )

    query = <<~QUERY
      query {
        employees(sort: { firstName: DESC }) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Sam", "lastName" => "Jeffrey" },
        { "firstName" => "Joe", "lastName" => "Smith" },
        { "firstName" => "Adam", "lastName" => "Thomas" },
      ]
    )
  end

  it "sorts top-level employees by multiple fields in the given order" do
    Employee.create!(first_name: "Sam", last_name: "Jeffrey")
    Employee.create!(first_name: "Joe", last_name: "Thomas")
    Employee.create!(first_name: "Joe", last_name: "Smith")

    query = <<~QUERY
      query {
        employees(sort: { firstName: ASC, lastName: ASC }) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Joe", "lastName" => "Smith" },
        { "firstName" => "Joe", "lastName" => "Thomas" },
        { "firstName" => "Sam", "lastName" => "Jeffrey" },
      ]
    )

    query = <<~QUERY
      query {
        employees(sort: { firstName: ASC, lastName: DESC }) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employees" => [
        { "firstName" => "Joe", "lastName" => "Thomas" },
        { "firstName" => "Joe", "lastName" => "Smith" },
        { "firstName" => "Sam", "lastName" => "Jeffrey" },
      ]
    )
  end

  it "sorts nested positions by title" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    department1 = Department.create!(name: "Paper Management")
    Position.create!(department: department1, employee: employee, title: "Regional Manager")
    department2 = Department.create!(name: "Pencil Pushing")
    Position.create!(department: department2, employee: employee, title: "Assistant to Regional Manager")

    query = <<~QUERY
      query {
        employees {
          firstName
          lastName
          positions(sort: { title: ASC }) {
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
            },
            {
              "title" => "Regional Manager"
            }
          ]
        }
      ]
    )

    query = <<~QUERY
      query {
        employees {
          firstName
          lastName
          positions(sort: { title: DESC }) {
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
              "title" => "Regional Manager"
            },
            {
              "title" => "Assistant to Regional Manager"
            }
          ]
        }
      ]
    )
  end
end
