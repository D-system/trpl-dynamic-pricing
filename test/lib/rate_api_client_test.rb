require "test_helper"

# The test class is here to get a sense of the return values of the rate-api.
# It is not exhaustive nor cover much business logic.
#
# See Api::V1::PricingService for the business logic.
class RateApiClientTest < ActiveSupport::TestCase
  PRICING_URL = "#{RateApiClient.base_uri}/pricing".freeze
  COMMON_REQUEST_ATTRIBUTES = [
    { period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom" },
  ].freeze

  test "call to API that returns all expected fields" do
    response_body = {
      rates: [
        {
          hotel: "FloatingPointResort",
          period: "Summer",
          rate: 49_000,
          room: "SingletonRoom",
        }
      ]
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: COMMON_REQUEST_ATTRIBUTES }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    result = RateApiClient.get_rate(period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom")
    assert_equal(result.success?, true)
    assert_equal(result.parsed_response["rates"].length, 1)

    api_value = result.parsed_response["rates"][0]
    assert_equal(api_value["hotel"], "FloatingPointResort")
    assert_equal(api_value["period"], "Summer")
    assert_equal(api_value["rate"], 49_000)
    assert_equal(api_value["room"], "SingletonRoom")
  end

  test "call to API with the return field 'rate' missing" do
    response_body = {
      rates: [
        {
          hotel: "FloatingPointResort",
          period: "Summer",
          room: "SingletonRoom",
        }
      ]
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: COMMON_REQUEST_ATTRIBUTES }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    result = RateApiClient.get_rate(period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom")
    assert_equal(result.success?, true)
    assert_equal(result.parsed_response["rates"].length, 1)

    api_value = result.parsed_response["rates"][0]
    assert_equal(api_value["hotel"], "FloatingPointResort")
    assert_equal(api_value["period"], "Summer")
    assert_equal(api_value.key?("rate"), false) # Key missing
    assert_equal(api_value["room"], "SingletonRoom")
  end


  test "call to API and return an error" do
    response_body = {
      message: "Failed to process rates due to an intermittent issue.",
      status: "error",
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: COMMON_REQUEST_ATTRIBUTES }.to_json).
      to_return(
        status: 500,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    result = RateApiClient.get_rate(period: "Summer", hotel: "FloatingPointResort", room: "SingletonRoom")
    assert_equal(result.success?, false)

    json = result.parsed_response
    assert_equal(json["message"], "Failed to process rates due to an intermittent issue.",)
    assert_equal(json["status"], "error")
  end
end
