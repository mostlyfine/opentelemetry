FROM ruby:3.3-slim

WORKDIR /app

COPY * .

RUN apt-get update -qq \
  && apt-get install -y build-essential libpq-dev \
  && bundle install

CMD ["bundle", "exec", "ruby", "app.rb"]
