Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://the-last-word-ui.vercel.app",
            /https:\/\/the-last-word-ui.*\.vercel\.app/,
            "http://localhost:5173", # Typical Vite local port
            "http://127.0.0.1:5173",
            "http://localhost:3000"  # In case you're running on 3000

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
