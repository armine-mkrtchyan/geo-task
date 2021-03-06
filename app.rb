require_relative 'dependencies'

class GeoTask < Sinatra::Base

  Mongoid.load!('config/mongoid.yml', :development)

  set :show_exceptions, :after_handler
  set(:auth) do |*types|
    condition { http_error 405 unless @current_user.among?(types) } unless types.empty?
  end

  error Mongoid::Errors::DocumentNotFound do |*args|
    http_error 404
  end

  error Mongoid::Errors::Validations do |err|
    http_error(403, {errors: err.document.errors}.to_json)
  end

  def http_error(code, body = HTTP_STATUS_CODES[code])
    halt error(code, body)
  end
  alias :http_response :http_error

  before do
    begin
      content_type :json
      if request.body.read(1)
        request.body.rewind
        @request_payload = JSON.parse(request.body.read, { symbolize_names: true })
      end
    rescue JSON::ParserError => e
      request.body.rewind
      http_error(400, 'Invalid JSON')
    end
  end

  require_relative 'models.inc'
  require_relative 'routes.inc'


  before %r{^(?!/(login|signup))} do
    @current_user = User.find_by!(token: env['HTTP_ACCESS_TOKEN']) rescue http_error(401)
  end

end
