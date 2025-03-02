# frozen_string_literal: true

# Класс для возрата результата
class Result
  attr_accessor :ans, :error

  def initialize(ans: {}, success: true, error: '')
    @ans = ans
    @success = success
    @error = error
  end

  def success? = @success

  class << self
    def error(err) = new(error: err, success: false)

    def success(ans) = new(ans: ans)
  end
end
