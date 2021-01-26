FROM ruby:2.7.1

WORKDIR /app
ADD . /app/
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby"]
CMD ["status", "--help"]
