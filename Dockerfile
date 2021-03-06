ARG FROM_IMG
FROM ${FROM_IMG}

ENV RUBY_MAJOR "2.3"
ENV RUBY_VERSION "2.3.3"
ENV RUBYGEMS_VERSION "2.6.14"
ENV BUNDLER_VERSION "1.16.1"
ENV NODE_VERSION "6.10.1"

ENV APT_PACKAGES " \
    git gcc g++ make patch binutils libc6-dev libjemalloc-dev \
    libffi-dev libssl-dev libyaml-dev zlib1g-dev libgmp-dev libxml2-dev \
    libxslt1-dev libpq-dev libreadline-dev libsqlite3-dev libmysqlclient-dev \
    tzdata file python-pip python-dev python-setuptools \
    "

ENV CURL_APT_PACKAGES " \
    autoconf automake autotools-dev libtool pkg-config \
    libcunit1-dev libev-dev libevent-dev libjansson-dev \
    cython python3-dev wget \
    "

ENV APT_REMOVE_PACKAGES "openssh-server postfix"

RUN apt-get update
RUN apt-get install -y --no-install-recommends $APT_PACKAGES
RUN apt-get install -y --no-install-recommends $CURL_APT_PACKAGES

RUN cd ~ && \
    apt-get build-dep -y curl

RUN wget http://curl.haxx.se/download/curl-7.60.0.tar.bz2 && \
    tar -xvjf curl-7.60.0.tar.bz2 && \
    cd curl-7.60.0 && \
    ./configure --with-nghttp2=/usr/local --with-ssl && \
    make && \
    make install && \
    ldconfig

RUN apt-get remove --purge -y $APT_REMOVE_PACKAGES
RUN apt-get autoremove --purge -y

WORKDIR /tmp

RUN curl https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz \
    |tar -xz -C /usr --strip-components=1

RUN curl -o ruby.tgz \
    "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-${RUBY_VERSION}.tar.gz" && \
    tar -xzf ruby.tgz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure --enable-shared --with-jemalloc --disable-install-doc && \
    make -j4 && \
    make install

ENV GEM_SPEC_CACHE "/tmp/gemspec"
RUN echo 'gem: --no-document' > $HOME/.gemrc
RUN gem update --system ${RUBYGEMS_VERSION}
RUN gem install -v ${BUNDLER_VERSION} bundler

RUN mkdir -p /root/app

WORKDIR /root/app
# Now update code dir and run gem install
COPY . /root/app
RUN bundle install
# Run Asset precompile
RUN bundle exec rake assets:precompile

# RUN cp -Ru /tmp/code/* /home/app/webapp