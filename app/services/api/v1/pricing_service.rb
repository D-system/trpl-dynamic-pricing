class Api::V1::PricingService < BaseService
  def initialize(period:, hotel:, room:)
    @period = period
    @hotel = hotel
    @room = room
  end

  def run
    # TODO: Start to implement here
    rate = RateApiClient.get_rate(period: @period, hotel: @hotel, room: @room)
    if rate.success?
      @result = if rate.parsed_response.include?('rates')
        rate.parsed_response['rates'].detect { |r| r['period'] == @period && r['hotel'] == @hotel && r['room'] == @room }&.dig('rate')
      else
        nil
      end
    else
      # The rate-api server returns `message` but our test suite rely on `error`.
      # TODO: verify if the `error` is still in use or not.
      errors << (rate.parsed_response['message'] || rate.parsed_response['error'])
    end
  end
end
