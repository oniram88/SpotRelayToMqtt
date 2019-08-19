# Create container for Ruby
FROM ruby:2.6 as development

RUN gem install bundler

RUN mkdir -p /app
WORKDIR /app
 
ADD Gemfile .
ADD Gemfile.lock .
 
# Bundle
RUN bundle install --full-index


FROM development

ADD . /app