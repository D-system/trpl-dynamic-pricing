require "test_helper"

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

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run

    assert_equal(pricing.valid?, true)
    assert_equal(pricing.result, 49_000)
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

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    pricing.run

    assert_equal(pricing.valid?, true)
    assert_nil(pricing.result)
    assert_equal(pricing.errors, [])
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
    assert_equal(pricing.errors, [I18n.t("rate_api.unknown_error")])
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

  test "fetch_value raise an exception" do
    service = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    service.stub(:fetch_value, -> { raise "Oops" }) do
      service.run
    end

    assert_equal(service.valid?, false)
    assert_equal(service.errors, [I18n.t("rate_api.technical_difficulties")])
    assert_nil(service.result)
  end

  test "fetch_value raise an Errno::ECONNREFUSED exception" do
    service = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    # Note: It's `TCPSocket.initialize` that raise the exception but WebHook already have a hook on it and stub the init method is to avoid.
    service.stub(:fetch_value, -> { raise Errno::ECONNREFUSED, "rate-api down: can not connect" }) do
      service.run
    end

    assert_equal(service.valid?, false)
    assert_equal(service.errors, [I18n.t("rate_api.service_down")])
    assert_nil(service.result)
  end

  test "the API timing out" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_timeout

    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)

    original_timeout = RateApiClient.default_options[:timeout]
    RateApiClient.default_timeout(1.second)

    pricing.run

    assert_equal(pricing.valid?, false)
    assert_equal(pricing.errors, [I18n.t("rate_api.service_timeout")])
  ensure
    RateApiClient.default_timeout(original_timeout)
  end
end
