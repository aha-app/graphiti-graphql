RSpec.describe Graphiti::GraphQL do
  it "queries single employee" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith"
      }
    )
  end

  it "queries employee with has_many through relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    department = Department.create!(name: "Paper Management")
    Position.create!(department: department, employee: employee, title: "Assistant to Regional Manager")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          positions {
            title
            department {
              name
            }
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "positions" => [
          {
            "title" => "Assistant to Regional Manager",
            "department" => {
              "name" => "Paper Management"
            }
          }
        ]
      }
    )
  end

  it "queries employee with has_many STI relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    Bug.create!(employee: employee, name: "Fix the paper cutter")
    Feature.create!(employee: employee, name: "Add blue paper")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          tasks {
            name
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "tasks" => [
          {
            "name" => "Fix the paper cutter"
          },
          {
            "name" => "Add blue paper"
          }
        ]
      }
    )
  end

  it "queries employee with polymorphic has_many relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    Note.create!(notable: employee, body: "Dear Joe")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          notes {
            body
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "notes" => [
          {
            "body" => "Dear Joe"
          }
        ]
      }
    )
  end

  it "queries employee with has_one relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    Salary.create!(employee: employee, base_rate: 10.0, overtime_rate: 15.0)

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          salary {
            baseRate
            overtimeRate
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "salary" => {
          "baseRate" => 10.0,
          "overtimeRate" => 15.0
        }
      }
    )
  end

  it "queries employee with polymorphic has_one relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    Location.create!(locatable: employee, latitude: "-48.52.6", longitude: "-123.23.6")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          location {
            latitude
            longitude
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "location" => {
          "latitude" => "-48.52.6",
          "longitude" => "-123.23.6"
        }
      }
    )
  end

  it "queries employee with many_to_many relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")
    team = Team.create!(name: "Paper Pushers")
    EmployeeTeam.create!(employee: employee, team: team)

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          teams {
            name
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "teams" => [{ "name" => "Paper Pushers" }]
      }
    )
  end

  it "queries employee with belongs_to relationship" do
    classification = Classification.create!(description: "Senior")
    employee = Employee.create!(first_name: "Joe", last_name: "Smith", classification: classification)

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          classification {
            description
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "classification" => {
          "description" => "Senior"
        }
      }
    )
  end

  it "queries employee with polymorphic belongs_to relationship" do
    workspace = Office.create!(address: "123 Joe St")
    employee = Employee.create!(first_name: "Joe", last_name: "Smith", workspace: workspace)

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          firstName
          lastName
          workspace {
            ... on Office {
              address
            }
          }
        }
      }
    QUERY
    expect(query).to respond_with(
      "employee" => {
        "firstName" => "Joe",
        "lastName" => "Smith",
        "workspace" => {
          "address" => "123 Joe St"
        }
      }
    )
  end

  it "returns nice error for unknown field" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          widget
        }
      }
    QUERY
    expect(query).to respond_with_errors(
      [
        {
          "message" => "Field 'widget' doesn't exist on type 'Employee'",
          "locations" => [
            { "line" => 3, "column" => 5 }
          ],
          "path" => ["query", "employee", "widget"],
          "extensions" => {
            "code" => "undefinedField",
            "typeName" => "Employee",
            "fieldName" => "widget"
          }
        }
      ]
    )
  end

  it "returns nice error for unknown relationship" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    query = <<~QUERY
      query {
        employee(id: #{employee.id}) {
          widget {
            name
          }
        }
      }
    QUERY
    expect(query).to respond_with_errors(
      [
        {
          "message" => "Field 'widget' doesn't exist on type 'Employee'",
          "locations" => [
            { "line" => 3, "column" => 5 }
          ],
          "path" => ["query", "employee", "widget"],
          "extensions" => {
            "code" => "undefinedField",
            "typeName" => "Employee",
            "fieldName" => "widget"
          }
        }
      ]
    )
  end
end
