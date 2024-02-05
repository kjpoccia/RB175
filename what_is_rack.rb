class MyApp
  def call(env)
    ['200', { "Content-Type" => "text/plain" }, ["hello world"]]
  end
end

class FriendlyGreeting
  def initialize(app)
    @app = app
  end

  def call(env)
    body = @app.call(env).last

    [
      '200',
      { "content-Type" => "text/plain" },
      body.prepend("A warm welcome to you!\n")
    ]
  end
end

class Wave
  def initialize(app)
    @app = app
  end

  def call(env)
    body = @app.call(env).last

    [
      '200',
      { "content-Type" => "text/plain" },
      body.prepend("Wave from afar!\n")
    ]
  end
end

Rack::Handler::WEBrick.run Wave.new(FriendlyGreeting.new(MyApp.new))