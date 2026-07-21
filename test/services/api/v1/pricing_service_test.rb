require "test_helper"

# The test class is here to get a sense of the return values of the rate-api.
# It is not exhaustive nor cover much business logic.
#
# See Api::V1::PricingService for the business logic.
class Api::V1::PricingServiceTest < ActiveSupport::TestCase
  PRICING_URL = "#{RateApiClient.base_uri}/pricing".freeze
  COMMON_REQUEST_ATTRIBUTES = {
    period: "Summer",
    hotel: "FloatingPointResort",
    room: "SingletonRoom"
  }.freeze

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
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    service = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    assert_equal(service.valid?, true)
    result = service.run
    assert_equal(result, 49_000)
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
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    result = RateApiClient.get_rate(**COMMON_REQUEST_ATTRIBUTES)
    assert_equal(result.success?, true)
    assert_equal(result.parsed_response["rates"].length, 1)

    api_value = result.parsed_response["rates"][0]
    assert_equal(api_value["hotel"], "FloatingPointResort")
    assert_equal(api_value["period"], "Summer")
    assert_equal(api_value.key?("rate"), false) # Key missing
    assert_equal(api_value["room"], "SingletonRoom")
  end

  test "call to API with the return field 'hotel' missing" do
    response_body = {
      rates: [
        {
          rate: 30_000,
          period: "Summer",
          room: "SingletonRoom",
        }
      ]
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run
    assert_equal(pricing.valid?, true)
    assert_nil(pricing.result)
  end

  test "call to API and return no object" do
    response_body = {}

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run
    assert_nil(pricing.result)
  end

  test "the API returns an error without expected errors attibutes and fallback" do
    response_body = {}

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 500,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run
    assert_nil(pricing.result)
    assert_equal(pricing.errors.length, 1)
    assert_equal(pricing.errors[0], I18n.t("rate_api.unknown_error"))
  end

  test "call to API and return an error (sample from rate-api response)" do
    response_body = {
      message: "Failed to process rates due to an intermittent issue.",
      status: "error",
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 500,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run
    assert_equal(pricing.valid?, false)

    assert_equal(pricing.errors, ["Failed to process rates due to an intermittent issue."],)
  end

  test "call to API and return an error (sample from existing test for Api::V1::PricingControllerTest)" do
    response_body = {
      message: "Failed to process rates due to an intermittent issue.",
      status: "error",
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 500,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run
    assert_equal(pricing.valid?, false)

    assert_equal(pricing.errors, ["Failed to process rates due to an intermittent issue."],)
  end
end
