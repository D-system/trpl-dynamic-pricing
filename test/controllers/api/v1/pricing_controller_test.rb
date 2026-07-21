require "test_helper"

class Api::V1::PricingControllerTest < ActionDispatch::IntegrationTest
  # TODO: mock the `Api::V1::PricingService`
  PRICING_URL = "#{RateApiClient.base_uri}/pricing".freeze
    COMMON_REQUEST_ATTRIBUTES = {
    period: "Summer",
    hotel: "FloatingPointResort",
    room: "SingletonRoom"
  }.freeze

  test "should get pricing with all parameters" do
    response_body = {
      'rates' => [
        { 'period' => 'Summer', 'hotel' => 'FloatingPointResort', 'room' => 'SingletonRoom', 'rate' => 15_000 }
      ]
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 200,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :success
    assert_equal "application/json", @response.media_type

    assert_equal 15_000, @response.parsed_body["rate"]
  end

  test "should return error when rate API fails" do
    response_body = {
      error: 'Rate not found'
    }

    stub_request(:post, PRICING_URL).
      with(body: { attributes: [COMMON_REQUEST_ATTRIBUTES] }.to_json).
      to_return(
        status: 500,
        headers: { "content-type": ["application/json"] },
        body: response_body.to_json,
      )

    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Rate not found"
  end

  test "should return error without any parameters" do
    get api_v1_pricing_url

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Missing required parameters"
  end

  test "should handle empty parameters" do
    get api_v1_pricing_url, params: {
      period: "",
      hotel: "",
      room: ""
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Missing required parameters"
  end

  test "should reject invalid period" do
    get api_v1_pricing_url, params: {
      period: "summer-2024",
      hotel: "FloatingPointResort",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Invalid period"
  end

  test "should reject invalid hotel" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "InvalidHotel",
      room: "SingletonRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Invalid hotel"
  end

  test "should reject invalid room" do
    get api_v1_pricing_url, params: {
      period: "Summer",
      hotel: "FloatingPointResort",
      room: "InvalidRoom"
    }

    assert_response :bad_request
    assert_equal "application/json", @response.media_type

    assert_includes @response.parsed_body["error"], "Invalid room"
  end
end
