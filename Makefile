# Requirements to build:
#   rsync
#   wget or curl
#
JRUBY_VERSION=1.7.11
ELASTICSEARCH_VERSION=1.1.1
LOGSTASH_VERSION?=1.4.2
LOGSTASH=build/tarball/logstash-$(LOGSTASH_VERSION)

LOGSTASH_URL=https://download.elasticsearch.org/logstash/logstash

WITH_JRUBY=java -jar $(shell pwd)/$(JRUBY) -S
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_URL=http://jruby.org.s3.amazonaws.com/downloads/$(JRUBY_VERSION)/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_CMD=java -jar $(JRUBY)

ELASTICSEARCH_URL=http://download.elasticsearch.org/elasticsearch/elasticsearch
ELASTICSEARCH=vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION)
PLUGIN_FILES=$(shell find lib -type f| egrep '^lib/logstash/(inputs|outputs|filters|codecs)/[^/]+$$' | egrep -v '/(base|threadable).rb$$|/inputs/ganglia/')
QUIET=@
ifeq (@,$(QUIET))
	QUIET_OUTPUT=> /dev/null 2>&1
endif

WGET=$(shell which wget 2>/dev/null)
CURL=$(shell which curl 2>/dev/null)

# OS-specific options
TARCHECK=$(shell tar --help|grep wildcard|wc -l|tr -d ' ')
ifeq (0, $(TARCHECK))
TAR_OPTS=
else
TAR_OPTS=--wildcards
endif

TESTS=$(wildcard spec/*.rb spec/**/*.rb spec/**/**/*.rb)

#spec/outputs/graphite.rb spec/outputs/email.rb)
default:
	@echo "Make targets you might be interested in:"
	@echo "  tarball -- builds the tarball package"
	@echo "  tarball-test -- runs the test suite against the tarball package"

.VERSION.mk:
	echo "VERSION=${LOGSTASH_VERSION}" >> $@

-include .VERSION.mk

version:
	@echo "Version: $(VERSION)"

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

.PHONY: clean
clean:
	@echo "=> Cleaning up"
	-$(QUIET)rm -rf .bundle
	-$(QUIET)rm -rf build
	-$(QUIET)rm -f pkg/*.deb
	-$(QUIET)rm .VERSION.mk

.PHONY: vendor-clean
vendor-clean:
	-$(QUIET)rm -rf vendor/kibana vendor/geoip vendor/collectd
	-$(QUIET)rm -rf vendor/jar vendor/ua-parser

.PHONY: clean-vendor
clean-vendor:
	-$(QUIET)rm -rf vendor

.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root
	$(QUIET)rsync -a --include "*/" --include "*.rb" --include "*.yaml" --exclude "*" ./lib/ ./build/ruby
	$(QUIET)rsync -a ./spec ./build/ruby
	@# Delete any empty directories copied by rsync.
	$(QUIET)find ./build/ruby -type d -empty -delete

vendor:
	$(QUIET)mkdir $@

vendor/jar: | vendor
	$(QUIET)mkdir $@

vendor-jruby: $(JRUBY)

$(JRUBY): | vendor/jar
	$(QUIET)echo "=> Downloading jruby $(JRUBY_VERSION)"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(JRUBY_URL)

vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz: | wget-or-curl vendor/jar
	@echo "=> Fetching elasticsearch"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(ELASTICSEARCH_URL)/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz

build/tarball/logstash-$(LOGSTASH_VERSION).tar.gz: | wget-or-curl build build/tarball
	@echo "=> Fetching logstash $(LOGSTASH_VERSION)"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(LOGSTASH_URL)/logstash-$(LOGSTASH_VERSION).tar.gz

.PHONY: vendor-elasticsearch
vendor-elasticsearch: $(ELASTICSEARCH)
$(ELASTICSEARCH): $(ELASTICSEARCH).tar.gz | vendor/jar
	@echo "=> Pulling the jars out of $<"
	$(QUIET)tar -C $(shell dirname $@) -xf $< $(TAR_OPTS) --exclude '*sigar*' \
		'elasticsearch-$(ELASTICSEARCH_VERSION)/lib/*.jar'

.PHONY: vendor-gems
vendor-gems: | vendor/bundle

.PHONY: vendor/bundle
vendor/bundle: | vendor $(JRUBY)
	@echo "=> Ensuring ruby gems dependencies are in $@..."
	$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 ./gembag.rb logstash-kafka.gemspec
	@# Purge any junk that fattens our jar without need!
	@# The riak gem includes previous gems in the 'pkg' dir. :(
	-$(QUIET)rm -rf $@/jruby/1.9/gems/riak-client-1.0.3/pkg
	@# Purge any rspec or test directories
	-$(QUIET)rm -rf $@/jruby/1.9/gems/*/spec $@/jruby/1.9/gems/*/test
	@# Purge any comments in ruby code.
	@#-find $@/jruby/1.9/gems/ -name '*.rb' | xargs -n1 sed -i -e '/^[ \t]*#/d; /^[ \t]*$$/d'

.PHONY: build
build:
	-$(QUIET)mkdir -p $@

build/ruby: | build
	-$(QUIET)mkdir -p $@

.PHONY: origin-logstash
origin-logstash: $(LOGSTASH)
$(LOGSTASH): $(LOGSTASH).tar.gz | build build/tarball
	@echo "=> Extracting $<"
		$(QUIET)tar -C $(shell dirname $@) -xf $< $(TAR_OPTS)
		$(QUIET)rm -rf $<

package: | prepare-tarball
	pkg/build.sh centos 6

build/tarball: | build
	-$(QUIET)mkdir $@

show:
	echo $(VERSION)

.PHONY: prepare-tarball
prepare-tarball tarball zip: WORKDIR=build/tarball/logstash-$(VERSION)
prepare-tarball: $(LOGSTASH) $(JRUBY) vendor-gems
prepare-tarball:
	@echo "=> Preparing tarball"
	$(QUIET)$(MAKE) $(WORKDIR)
	$(QUIET)rsync -a --relative lib spec vendor/bundle/jruby vendor/jar --exclude 'vendor/bundle/jruby/1.9/cache' --exclude 'vendor/bundle/jruby/1.9/gems/*/doc' --exclude 'vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz' $(WORKDIR)

.PHONY: tarball
tarball: | build/logstash-$(VERSION).tar.gz
build/logstash-$(VERSION).tar.gz: | prepare-tarball
	$(QUIET)tar -C $$(dirname $(WORKDIR)) -c $$(basename $(WORKDIR)) \
		| gzip -9c > $@
	@echo "=> tarball ready: $@"

.PHONY: zip
zip: | build/logstash-$(VERSION).zip
build/logstash-$(VERSION).zip: | prepare-tarball
	$(QUIET)(cd $$(dirname $(WORKDIR)); find $$(basename $(WORKDIR)) | zip $(PWD)/$@ -@ -9)$(QUIET_OUTPUT)
	@echo "=> zip ready: $@"

.PHONY: tarball-test
tarball-test: #build/logstash-$(VERSION).tar.gz
	$(QUIET)-rm -rf build/test-tarball/
	$(QUIET)mkdir -p build/test-tarball/
	tar -C build/test-tarball --strip-components 1 -xf build/logstash-$(VERSION).tar.gz
	(cd build/test-tarball; bin/logstash rspec spec/**/kafka*.rb)
