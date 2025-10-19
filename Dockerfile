FROM ruby:latest

RUN gem install rackup sinatra puma
RUN gem install open-uri cairo

COPY views ./views

COPY api ./api

COPY public ./public

COPY data ./data

EXPOSE 80

CMD ["ruby", "api/myapp.rb", "-o", "0.0.0.0", "-p", "80"]