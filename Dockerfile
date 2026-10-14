FROM ruby:3.4-slim

# build-essential: puma / nio4r native extensions
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# chino's preview server (Sinatra) binds 0.0.0.0:4444
EXPOSE 4444

CMD ["bundle", "exec", "chino"]
