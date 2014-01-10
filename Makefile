# Requirements to build:
#   rsync
#   wget or curl
#
JRUBY_VERSION=1.7.5

WITH_JRUBY=java -jar $(shell pwd)/$(JRUBY) -S
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_URL=http://jruby.org.s3.amazonaws.com/downloads/$(JRUBY_VERSION)/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_CMD=java -jar $(JRUBY)
JRUBYC=$(WITH_JRUBY) jrubyc

KAFKA_VERSION=0.8.0
LOGSTASH_VERSION=1.2.2
VENDOR_DIR=vendor/bundle/jruby/1.9

KAFKA_URL=http://apache.mirrors.pair.com/kafka/0.8.0/kafka_2.8.0-0.8.0.tar.gz

LOGSTASH_URL=https://download.elasticsearch.org/logstash/logstash/logstash-1.2.2-flatjar.jar

WGET=$(shell which wget 2>/dev/null)
CURL=$(shell which curl 2>/dev/null)

QUIET=@

# OS-specific options
TARCHECK=$(shell tar --help|grep wildcard|wc -l|tr -d ' ')
ifeq (0, $(TARCHECK))
TAR_OPTS=
else
TAR_OPTS=--wildcards
endif

# Figure out if we're using wget or curl
.PHONY: wget-or-curl
wget-or-curl:
ifeq ($(CURL),)
ifeq ($(WGET),)
@echo "wget or curl are required."
	exit 1
else
DOWNLOAD_COMMAND=wget -q --no-check-certificate -O
endif
else
DOWNLOAD_COMMAND=curl -s -L -k -o
endif

clean: clean-vendor clean-build

clean-vendor:
	$(QUIET)rm -rf vendor

clean-build:
	$(QUIET)rm -rf build

build:
	-$(QUIET)mkdir -p $@

build/ruby: | build
	-$(QUIET)mkdir -p $@

vendor:
	$(QUIET)mkdir -p $@

vendor/jar: vendor
	$(QUIET)mkdir -p $@


get-kafka: | vendor/jar
	@echo "=> Fetching kafka"
	$(QUIET)$(DOWNLOAD_COMMAND) vendor/kafka_2.8.0-$(KAFKA_VERSION).tar.gz $(KAFKA_URL)

	@echo "=> Pulling the jars out of Kafka"
	$(QUIET)tar -C vendor/jar -xf vendor/kafka_2.8.0-$(KAFKA_VERSION).tar.gz $(TAR_OPTS) \
		--strip-components 2 'kafka_2.8.0-$(KAFKA_VERSION)/libs/*.jar'
	$(QUIET)tar -C vendor/jar -xf vendor/kafka_2.8.0-$(KAFKA_VERSION).tar.gz $(TAR_OPTS) \
		--strip-components 1 'kafka_2.8.0-$(KAFKA_VERSION)/*.jar'
	$(QUIET)rm -rf vendor/jar/libs/

get-logstash: | vendor/jar
	@echo "=> Fetching logstash jar"
	$(QUIET)$(DOWNLOAD_COMMAND) vendor/jar/logstash-$(LOGSTASH_VERSION)-flatjar.jar $(LOGSTASH_URL)

build/monolith: get-logstash get-kafka $(JRUBY) vendor-gems copy-ruby-files | build
	$(QUIET)mkdir -p $@
	@# Unpack all the 3rdparty jars and any jars in gems
	$(QUIET)find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| (cd $@; xargs -n1 jar xf)
	@# Merge all service file in all 3rdparty jars
	$(QUIET)mkdir -p $@/META-INF/services/
	$(QUIET)find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| xargs $(JRUBY_CMD) extract_services.rb -o $@/META-INF/services
	-$(QUIET)rm -f $@/META-INF/*.LIST
	-$(QUIET)rm -f $@/META-INF/*.MF
	-$(QUIET)rm -f $@/META-INF/*.RSA
	-$(QUIET)rm -f $@/META-INF/*.SF
	-$(QUIET)rm -f $@/META-INF/NOTICE $@/META-INF/NOTICE.txt
	-$(QUIET)rm -f $@/META-INF/LICENSE $@/META-INF/LICENSE.txt

build-jruby: $(JRUBY)

$(JRUBY): | vendor/jar
	$(QUIET)echo "=> Downloading jruby $(JRUBY_VERSION)"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(JRUBY_URL)

vendor-gems: | vendor/bundle

vendor/bundle: | vendor $(JRUBY)
	@echo "=> Installing gems to $@..."
	$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 ./gembag.rb logstash-kafka.gemspec
	$(QUIET)-rm -rf $@/jruby/1.9/gems/riak-client-1.0.3/pkg
	@# Purge any rspec or test directories
	$(QUIET)-rm -rf $@/jruby/1.9/gems/*/spec $@/jruby/1.9/gems/*/test
	@# Purge any comments in ruby code.
	@#-find $@/jruby/1.9/gems/ -name '*.rb' | xargs -n1 sed -i -re '/^[ \t]*#/d; /^[ \t]*$$/d'
	$(QUIET)touch $@

.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root
	$(QUIET)rsync -a --include "*/" --include "*.rb" --exclude "*" ./lib/ ./build/ruby
	@# Delete any empty directories copied by rsync.
	$(QUIET)find ./build/ruby -type d -empty -delete

build/flatgems: | build vendor/bundle
	@echo "=> Copy external gems"
	mkdir $@
	for i in $(VENDOR_DIR)/gems/*/lib; do \
			rsync -a $$i/ $@/$$(basename $$i) ; \
	done

build/jar: | build build/flatgems build/monolith
	$(QUIET)mkdir build/jar
	$(QUIET)rsync -a build/monolith/ build/ruby/ build/flatgems/ build/jar/

flatjar: build/logstash-$(LOGSTASH_VERSION)-flatjar-kafka-$(KAFKA_VERSION).jar
build/logstash-$(LOGSTASH_VERSION)-flatjar-kafka-$(KAFKA_VERSION).jar: | build/jar
	$(QUIET)rm -f $@
	$(QUIET)jar cfe $@ logstash.runner -C build/jar .
	@echo "Created $@"
