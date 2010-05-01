require "rubygems"
require "sinatra"
require "haml"
require "uri"
require "yajl/http_stream"
require "json"
require "pit"

# doesn't work on thin and webrick
set :server, "mongrel"
set :public, File.dirname(__FILE__) + "/static"

get "/" do
  haml :index
end

get "/push" do
  boundary = "|||"
  response["Content-Type"] = %{multipart/mixed; boundary="#{boundary}"}

  MultipartResponse.new(boundary, "text/javascript")
end

class MultipartResponse
  def initialize(boundary, content_type)
    config = Pit.get("twitter.com", :require => {
      "username" => "your username in twitter",
      "password" => "your password in twitter"
    })

    @boundary     = boundary
    @content_type = content_type
    @uri          = URI.parse("http://#{config['username']}:#{config['password']}@chirpstream.twitter.com/2b/user.json")
  end

  def each
    Yajl::HttpStream.get(@uri) do |data|
      if data["user"]
        yield "--#{@boundary}\nContent-Type: #{@content_type}\n(#{data.to_json})"
      end
    end
  end
end
