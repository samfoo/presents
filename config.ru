require './presents'

run Rack::Cascade.new [UIApp, PresentsApp]
