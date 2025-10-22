FROM ruby:latest

RUN apt update && apt install -y fonts-ipafont

RUN gem install rackup sinatra puma
RUN gem install open-uri cairo

WORKDIR /opt/hsr_party_score

COPY api ./api

COPY public ./public

EXPOSE 80

CMD ["ruby", "api/myapp.rb", "-o", "0.0.0.0", "-p", "80"]