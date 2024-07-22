FROM slampis/ruby:3.1.2-bullseye-jemalloc-p1

RUN gem install bundler

WORKDIR /app

# docker build -t injest-client:latest .
# docker run --rm -it -v ${PWD}:/app injest-client:latest /bin/bash