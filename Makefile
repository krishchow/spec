all: build

COSI_SPEC := spec.md
COSI_PROTO := cosi.proto

# This is the target for building the temporary COSI protobuf file.
#
# The temporary file is not versioned, and thus will always be
# built on Travis-CI.
$(COSI_PROTO).tmp: $(COSI_SPEC) Makefile
	echo "// Code generated by make; DO NOT EDIT." > "$@"
	cat $< | sed -n -e '/```protobuf$$/,/^```$$/ p' | sed '/^```/d' >> "$@"

# This is the target for building the COSI protobuf file.
#
# This target depends on its temp file, which is not versioned.
# Therefore when built on Travis-CI the temp file will always
# be built and trigger this target. On Travis-CI the temp file
# is compared with the real file, and if they differ the build
# will fail.
#
# Locally the temp file is simply copied over the real file.
$(COSI_PROTO): $(COSI_PROTO).tmp
ifeq (true,$(TRAVIS))
	diff "$@" "$?"
else
	diff "$@" "$?" > /dev/null 2>&1 || cp -f "$?" "$@"
endif

build: check

# If this is not running on Travis-CI then for sake of convenience
# go ahead and update the language bindings as well.
ifneq (true,$(TRAVIS))
build:
	$(MAKE) -C lib/go
	$(MAKE) -C lib/cxx
endif

clean:
	$(MAKE) -C lib/go $@

clobber: clean
	$(MAKE) -C lib/go $@
	rm -f $(COSI_PROTO) $(COSI_PROTO).tmp

# check generated files for violation of standards
check: $(COSI_PROTO)
	awk '{ if (length > 72) print NR, $$0 }' $? | diff - /dev/null

.PHONY: clean clobber check
