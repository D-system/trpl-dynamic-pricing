require "test_helper"

class Api::V1::PricingServiceLoadTestTest < ActiveSupport::TestCase
  PRICING_URL = "#{RateApiClient.base_uri}/pricing".freeze
  COMMON_REQUEST_ATTRIBUTES = {
    period: "Summer",
    hotel: "FloatingPointResort",
    room: "SingletonRoom"
  }.freeze

  COMMON_RESPONSE_BODY = {
    rates: [
      {
        hotel: "FloatingPointResort",
        period: "Summer",
        rate: 49_000,
        room: "SingletonRoom",
      }
    ]
  }

  test "load test without cache" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMON_RESPONSE_BODY.to_json,
      )

    # Minimum number of calls to the service to satisfy is 10k calls per day
    # With 1000 calls in 1 seconds, it's roughly 10000 times the requirement.
    # It help to take in account the rate-api response speed and network latency.
    minimum_operation = 1_000
    timeout = 1.seconds
    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)

    assert_nothing_raised do
      Timeout.timeout(timeout) do
        minimum_operation.times.each do
          pricing.run
        end
      end
    end
  end

  test "load test with cache" do
    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: COMMON_RESPONSE_BODY.to_json,
      )

    # Minimum number of calls to the service to satisfy is 10k calls per day
    # With 1000 calls in 1 seconds, it's roughly 10000 times the requirement.
    # It help to take in account the rate-api response speed and network latency.
    minimum_operation = 1_000
    timeout = 1.seconds
    pricing = Api::V1::PricingService.new(**COMMON_REQUEST_ATTRIBUTES)

    assert_nothing_raised do
      Rails.cache.with_local_cache do
        Timeout.timeout(timeout) do
          minimum_operation.times.each do
            pricing.run
          end
        end
      end
    end
  end
end
