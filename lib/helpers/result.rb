class Result
	attr_accessor :ans, :error

	def initialize(ans: {}, success: true, error: '')
		@ans, @success, @error = ans, success, error
	end

	def success? = @success

	class << self

		def error(e) = self.new(error: e, success: false)

		def success(a) = self.new(ans: a)

	end	
end