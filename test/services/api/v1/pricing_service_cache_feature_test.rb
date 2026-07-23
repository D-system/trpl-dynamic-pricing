require "test_helper"

class Api::V1::PricingServiceCacheFeatureTest < ActiveSupport::TestCase
  PRICING_URL = "#{RateApiClient.base_uri}/pricing".freeze
  COMMON_REQUEST_ATTRIBUTES = {
    period: "Summer",
    hotel: "FloatingPointResort",
    room: "SingletonRoom"
  }.freeze

  COMMOM_VALID_RESPONSE_BODY = {
      rates: [
        {
          hotel: "FloatingPointResort",
          period: "Summer",
          rate: 49_000,
          room: "SingletonRoom",
        }
      ]
    }

  test "the cache is disabled by default in test" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMOM_VALID_RESPONSE_BODY.to_json,
      )

    service = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
    service.run
    service.run

    assert_requested(:post, PRICING_URL, times: 2)
  end

  test "call the service twice with the same arguments and cache the second call" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMOM_VALID_RESPONSE_BODY.to_json,
      )

    Rails.cache.with_local_cache do
      service1 = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
      service1.run
      service2 = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
      service2.run
    end
    assert_requested(:post, PRICING_URL, times: 1)
  end

  test "call the service twice with the same arguments, the API returns an error the first time that all the second invocation to call the API" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMOM_VALID_RESPONSE_BODY.to_json,
      )

    Rails.cache.with_local_cache do
      service = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
      service.stub(:fetch_value, -> { raise "Oops" }) do
        service.run
      end
      assert_requested(:post, PRICING_URL, times: 0)

      service.run
      assert_requested(:post, PRICING_URL, times: 1)
    end
  end

  test "call the service twice with different arguments, the second does not hit the cache as different" do
    stub1 = stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMOM_VALID_RESPONSE_BODY.to_json,
      )

    attributes2 = COMMON_REQUEST_ATTRIBUTES.dup
    attributes2[:period] = "Winter"
    stub2 = stub_request(:post, PRICING_URL).
      with(body: { attributes: [attributes2] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMOM_VALID_RESPONSE_BODY.to_json,
      )

    refute_equal(COMMON_REQUEST_ATTRIBUTES, attributes2)

    Rails.cache.with_local_cache do
      service1 = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)
      service1.run
      service2 = Api::V1::PricingService.new(**attributes2)
      service2.run
    end

    assert_requested(stub1, times: 1)
    assert_requested(stub2, times: 1)
  end
end
