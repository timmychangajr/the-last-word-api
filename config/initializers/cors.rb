Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://the-last-word-ui.vercel.app", /https:\/\/the-last-word-ui.*\.vercel\.app/

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true # Crucial if you ever add cookies/sessions
  end
end
