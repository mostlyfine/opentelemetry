require 'rubygems'
require 'bundler/setup'

Bundler.require

#ENV['OTEL_TRACES_EXPORTER'] ||= 'console'  # debug

OpenTelemetry::SDK.configure do |c|
  c.use_all
end

Pyroscope.configure do |c|
  c.application_name = 'sample-app'
  c.server_address = ENV['PYROSCOPE_SERVER_ADDRESS']
end

set :bind, '0.0.0.0'
set :port, 5002

get "/" do
  content_type :json
  response = {
    body: 'welcome to sinatra',
  }
  response.to_json
end


get "/weather" do
  content_type :json

  uri = URI.parse("https://www.jma.go.jp/bosai/forecast/data/overview_forecast/130000.json")
  response = Net::HTTP.get_response(uri)
  response.body.force_encoding("UTF-8")
end
