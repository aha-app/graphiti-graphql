ActiveRecord::Schema.define(version: 1) do
  create_table :classifications do |t|
    t.string :description
  end

  create_table :offices do |t|
    t.string :address
  end

  create_table :home_offices do |t|
    t.string :address
  end

  create_table :teams do |t|
    t.string :name
  end

  create_table :tasks do |t|
    t.integer :employee_id
    t.string :type
    t.string :name
  end

  create_table :notes do |t|
    t.integer :notable_id
    t.string :notable_type
    t.text :body
  end

  create_table :employee_teams do |t|
    t.integer :team_id
    t.integer :employee_id
  end

  create_table :employees do |t|
    t.string :workspace_type
    t.integer :workspace_id
    t.integer :classification_id
    t.string :first_name
    t.string :last_name
    t.integer :age
    t.string :nickname
    t.string :salutation
    t.string :professional_titles
    t.integer :group
    t.integer :headcount
  end

  create_table :positions do |t|
    t.belongs_to :department, index: true
    t.belongs_to :employee, index: true
    t.string :title
  end

  create_table :departments do |t|
    t.string :name
  end

  create_table :salaries do |t|
    t.integer :employee_id
    t.decimal :base_rate
    t.decimal :overtime_rate
  end

  create_table :locations do |t|
    t.integer :locatable_id
    t.string :locatable_type
    t.string :latitude
    t.string :longitude
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  attr_accessor :force_validation_error

  before_save do
    add_validation_error if force_validation_error

    if Rails::VERSION::MAJOR >= 5
      throw(:abort) if errors.present?
    else
      errors.blank?
    end
  end

  def add_validation_error
    errors.add(:base, "Forced validation error")
  end
end

class Classification < ApplicationRecord
end

class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
end

class Team < ApplicationRecord
  has_many :employee_teams
  has_many :employees, through: :employee_teams
end

class EmployeeTeam < ApplicationRecord
  belongs_to :team
  belongs_to :employee
end

class Office < ApplicationRecord
  has_many :employees, as: :workspace
end

class HomeOffice < ApplicationRecord
  has_many :employees, as: :workspace
end

class Task < ApplicationRecord
  belongs_to :employee
end

class Bug < Task
end

class Feature < Task
end

class Employee < ApplicationRecord
  belongs_to :workspace, polymorphic: true
  belongs_to :classification
  has_many :positions
  has_many :tasks
  has_many :bugs
  has_many :features
  has_many :notes, as: :notable
  has_one :location, as: :locatable
  validates :first_name, :last_name, presence: true
  validates :delete_confirmation,
    presence: true,
    on: :destroy

  has_many :employee_teams
  has_many :teams, through: :employee_teams

  has_one :salary

  enum group: [:engineering, :marketing, :sales]
  enum headcount: {
    0 => 0,
    100 => 100,
    1000 => 1000
  }

  before_destroy do
    add_validation_error if force_validation_error

    if Rails::VERSION::MAJOR >= 5
      throw(:abort) if errors.present?
    else
      errors.blank?
    end
  end
end

class Position < ApplicationRecord
  belongs_to :employee
  belongs_to :department
end

class Department < ApplicationRecord
  has_many :positions
end

class Salary < ApplicationRecord
  belongs_to :employee
end

class Location < ApplicationRecord
  belongs_to :locatable, polymorphic: true
end

class ApplicationResource < Graphiti::Resource
  include Graphiti::GraphQL::Resource

  self.adapter = Graphiti::Adapters::ActiveRecord
  self.abstract_class = true
end

class ClassificationResource < ApplicationResource
  attribute :description, :string
end

class TeamResource < ApplicationResource
  attribute :name, :string
end

class DepartmentResource < ApplicationResource
  attribute :name, :string
end

class PositionResource < ApplicationResource
  attribute :employee_id, :integer, only: [:writable, :filterable]
  attribute :title, :string
  belongs_to :department
end

class TaskResource < ApplicationResource
  self.polymorphic = %w[BugResource FeatureResource]
  attribute :name, :string
  attribute :employee_id, :string, only: [:writable, :filterable]
end

class BugResource < TaskResource
end

class FeatureResource < TaskResource
end

class OfficeResource < ApplicationResource
  attribute :address, :string
end

class HomeOfficeResource < ApplicationResource
  self.description = "An employee's primary office location"

  attribute :address, :string
end

class SalaryResource < ApplicationResource
  self.description = "An employee salary"

  attribute :employee_id, :integer, only: [:writable, :filterable]
  attribute :base_rate, :float
  attribute :overtime_rate, :float
end

class EmployeeResource < ApplicationResource
  self.description = "A worker at the company"

  graphql

  attribute :first_name, :string, description: "The employee's first name"
  attribute :last_name, :string, description: "The employee's last name"
  attribute :age, :integer
  attribute :group, :string_enum, allow: Employee.groups.keys
  attribute :headcount, :integer_enum, allow: Employee.headcounts.keys

  extra_attribute :nickname, :string
  extra_attribute :salutation, :string
  extra_attribute :professional_titles, :string

  has_many :positions
  has_many :tasks
  has_one :salary
  belongs_to :classification
  many_to_many :teams, description: "Teams the employee belongs to"
  polymorphic_has_many :notes, as: :notable
  polymorphic_has_one :location, as: :locatable
  polymorphic_belongs_to :workspace, description: "The employee's primary work area" do
    group_by(:workspace_type) do
      on(:Office)
      on(:HomeOffice)
    end
  end
end

class NoteResource < ApplicationResource
  attribute :notable_id, :integer
  attribute :notable_type, :string
  attribute :body, :string
end

class EmployeeSearchResource < ApplicationResource
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :age, :integer
end

class LocationResource < ApplicationResource
  attribute :locatable_id, :integer
  attribute :locatable_type, :string
  attribute :latitude, :string
  attribute :longitude, :string
end
