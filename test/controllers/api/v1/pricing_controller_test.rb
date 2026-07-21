require "test_helper"

class Api::V1::PricingControllerTest < ActionDispatch::IntegrationTest
  test "should get pricing with all parameters" do
    mock_service = Api::V1::PricingService.new(period: nil, hotel: nil, room: nil)
    mock_service.result = 15_000
    def mock_service.run = nil

    Api::V1::PricingService.stub(:new, mock_service) do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :success
      assert_equal "application/json", @response.media_type

      assert_equal 15_000, @response.parsed_body["rate"]
    end
  end

  test "should return error when rate API fails" do
    mock_service = Api::V1::PricingService.new(period: nil, hotel: nil, room: nil)
    mock_service.errors << "Rate not found"
    def mock_service.run = nil

    Api::V1::PricingService.stub(:new, mock_service) do
      get api_v1_pricing_url, params: {
        period: "Summer",
        hotel: "FloatingPointResort",
        room: "SingletonRoom"
      }

      assert_response :bad_request
      assert_equal "application/json", @response.media_type

      assert_includes @response.parsed_body["error"], "Rate not found"
    end
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
