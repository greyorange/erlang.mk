# Targets related to working with multiple erlang versions

ifeq ($(ERLANG_VERSION_SWITCHED),)
ifeq ($(IS_APP)$(IS_DEP),)

TEV_WORDS = $(subst ., ,${TARGET_ERLANG_VERSION})
TEV_MAJOR = $(firstword ${TEV_WORDS})
TEV_MINOR = $(word 2,${TEV_WORDS})
TEV_PATCH = $(word 3,${TEV_WORDS})

define eval_erlang_version.erl
	VersionFile = filename:join([code:root_dir(), "releases",
															erlang:system_info(otp_release),
															"OTP_VERSION"]),
	{ok, Version} = file:read_file(VersionFile),
	io:format("OTP-~s", [string:strip(erlang:binary_to_list(Version))]),
	halt(0).
endef


CURRENT_ERLANG_VERSION = $(shell $(call erlang,$(eval_erlang_version.erl)))

CEV_WORDS = $(subst ., ,${CURRENT_ERLANG_VERSION})
CEV_MAJOR = $(firstword ${CEV_WORDS})
CEV_MINOR = $(word 2,${CEV_WORDS})
CEV_PATCH = $(word 3,${CEV_WORDS})


$(info Current erlang version is ${CURRENT_ERLANG_VERSION} and target version is ${TARGET_ERLANG_VERSION}.)

VERSION_DISALLOWED = 0

ifneq ($(TARGET_ERLANG_VERSION),) # If target erlang version is defined

# Check if major version is equal and minor is >=
ifneq ($(shell test ${CEV_MAJOR} = ${TEV_MAJOR} && test ${CEV_MINOR} && test ${CEV_MINOR} -ge ${TEV_MINOR}; echo $$?),0)
VERSION_DISALLOWED = 1
else
ifeq ($(CEV_MINOR),$(TEV_MINOR))
ifneq ($(TEV_PATCH),)
ifeq ($(CEV_PATCH),)
VERSION_DISALLOWED = 1
else
ifeq ($(shell test ${CEV_PATCH} -lt ${TEV_PATCH}; echo $$?),0)
VERSION_DISALLOWED = 1
endif
endif
endif
endif
endif

else
$(info Erlang version not enforced by Makefile.)
endif

ifneq ($(VERSION_DISALLOWED),0)

# Check if running in Jenkins.
ifneq ($(BUILD_ID),)
ERLANG_OTP= $(COMPILE_ERLANG_VERSION)
export PATH := $(KERL_INSTALL_DIR)/$(ERLANG_OTP)/bin:$(PATH)
SHELL := env PATH=$(PATH) $(SHELL)
$(eval $(call kerl_otp_target,$(ERLANG_OTP)))

ifeq ($(wildcard $(KERL_INSTALL_DIR)/$(ERLANG_OTP))$(BUILD_ERLANG_OTP),)
$(info Building Erlang/OTP $(ERLANG_OTP)... Please wait...)
$(shell $(MAKE) $(KERL_INSTALL_DIR)/$(ERLANG_OTP) ERLANG_OTP=$(ERLANG_OTP) BUILD_ERLANG_OTP=1 >&2)
endif
$(info Automatically switched to Erlang version ${CURRENT_ERLANG_VERSION}.)
ERLANG_VERSION_SWITCHED=1
export ERLANG_VERSION_SWITCHED

else
$(error \
${newline}    Your current Erlang version is ${CURRENT_ERLANG_VERSION}, but the Makefile requires ${TARGET_ERLANG_VERSION}.\
${newline}    Major version must match, and minor version must be >= the required version.\
${newline}    If minor version = required minor version, then patch version must be >= required patch version.\
${newline}    Please install or activate ${TARGET_ERLANG_VERSION} and re-run this command.\
${newline}    For help, please consult: https://work.greyorange.com/confluence/x/o5CTAg )
endif
else
ERLANG_VERSION_SWITCHED=1
export ERLANG_VERSION_SWITCHED
$(info Erlang version is allowed.)
endif

endif
endif
