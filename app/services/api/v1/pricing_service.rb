class Api::V1::PricingService < BaseService
  def initialize(period:, hotel:, room:)
    @period = period
    @hotel = hotel
    @room = room
  end

  def run
    # TODO: Start to implement here
    @result = fetch_value
  end

  private

  def fetch_value
    rate = RateApiClient.get_rate(period: @period, hotel: @hotel, room: @room)
    if rate.success?
      if rate.parsed_response.include?('rates')
        rate.parsed_response['rates'].detect { |r| r['period'] == @period && r['hotel'] == @hotel && r['room'] == @room }&.dig('rate')
      else
        nil
      end
    else
      # The rate-api server returns `message` but our test suite rely on `error`.
      # TODO: verify if the `error` is still in use or not.
      error_message = (rate.parsed_response['message'] || rate.parsed_response['error'])

      if error_message.nil?
        error_message = I18n.t("rate_api.unknown_error")
        Rails.logger.error("RateApiClient returned an error without an error message. period: #{@period}, hotel: #{@hotel}, room: #{@room}")
      end

      errors << error_message
      nil # error path: no value returned
    end
  end
end
