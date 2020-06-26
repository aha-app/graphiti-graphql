RSpec::Matchers.define :respond_with do |hash|
  description { "respond with data matching #{hash}" }

  match do |query|
    @result = ApplicationResource.graphql_schema.execute(query)
    @result.to_h["data"] == hash
  end

  failure_message do |query|
    if @result["errors"]
      "Expected query to respond with data matching #{hash} but it returned errors #{@result["errors"]}"
    else
      "Expected query to respond with data matching #{hash} but it returned #{@result["data"]}"
    end
  end
end

RSpec::Matchers.define :respond_with_errors do |hash|
  description { "respond with errors matching #{hash}" }

  match do |query|
    result = ApplicationResource.graphql_schema.execute(query)
    result.to_h["errors"] == hash
  end

  failure_message do |query|
    result = ApplicationResource.graphql_schema.execute(query).to_h
    if result["data"]
      "Expected query to respond with errors matching #{hash} but it returned data #{result["data"]}"
    else
      "Expected query to respond with errors matching #{hash} but it returned #{result["errors"]}"
    end
  end
end
