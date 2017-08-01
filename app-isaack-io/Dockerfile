FROM ruby:2.2
MAINTAINER mugithi <isackaranja@gmail.com>

RUN apt-get update \
  && apt-get install -y \
  node \
  python-pygments \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN gem install \
  github-pages:99 \
  jekyll:3.2.1 \
  jekyll-redirect-from:0.11.0  \
  kramdown:1.12.0 \
  rdiscount:2.2.0.1 \
  rouge:2.0.6 \
  redcarpet:3.3.4 \
  git

RUN mkdir /src
COPY site /src
EXPOSE 4000


WORKDIR /src
ENTRYPOINT ["jekyll"]
