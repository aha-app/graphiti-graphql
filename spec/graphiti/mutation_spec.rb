RSpec.describe Graphiti::GraphQL do
  it "creates an employee" do
    mutation = <<~MUTATION
      mutation {
        createEmployee(firstName: "Jack", lastName: "Thompson") {
          employee {
            firstName
            lastName
          }
        }
      }
    MUTATION
    expect(mutation).to respond_with(
      "createEmployee" => {
        "employee" => {
          "firstName" => "Jack",
          "lastName" => "Thompson"
        }
      }
    )
    expect(Employee.find_by(first_name: "Jack", last_name: "Thompson")).to_not be_nil
  end

  it "returns error for failed create validation" do
    mutation = <<~MUTATION
      mutation {
        createEmployee(firstName: "Jack") {
          errors
        }
      }
    MUTATION
    expect(mutation).to respond_with(
      "createEmployee" => {
        "errors" => {
          "lastName" => "can't be blank"
        }
      }
    )
    expect(Employee.find_by(first_name: "Jack")).to be_nil
  end

  it "updates an employee" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    mutation = <<~MUTATION
      mutation {
        updateEmployee(id: #{employee.id}, firstName: "Jack", lastName: "Thompson") {
          employee {
            firstName
            lastName
          }
        }
      }
    MUTATION
    expect(mutation).to respond_with(
      "updateEmployee" => {
        "employee" => {
          "firstName" => "Jack",
          "lastName" => "Thompson"
        }
      }
    )
    employee.reload
    expect(employee.first_name).to eq("Jack")
    expect(employee.last_name).to eq("Thompson")
  end

  it "returns error for failed update validation" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    mutation = <<~MUTATION
      mutation {
        updateEmployee(id: #{employee.id}, lastName: "") {
          errors
        }
      }
    MUTATION
    expect(mutation).to respond_with(
      "updateEmployee" => {
        "errors" => {
          "lastName" => "can't be blank"
        }
      }
    )
    employee.reload
    expect(employee.first_name).to eq("Joe")
    expect(employee.last_name).to eq("Smith")
  end

  it "destroys an employee" do
    employee = Employee.create!(first_name: "Joe", last_name: "Smith")

    mutation = <<~MUTATION
      mutation {
        destroyEmployee(id: #{employee.id}) {
          employee {
            id
          }
        }
      }
    MUTATION
    expect(mutation).to respond_with(
      "destroyEmployee" => {
        "employee" => {
          "id" => employee.id.to_s,
        }
      }
    )
    expect(Employee.find_by(id: employee.id)).to be_nil
  end
end
