# Copyright 2017, Stanislaw Klekot <dozzie@jarowit.net>
# This file is part of erlang.mk and subject to the terms of the ISC License.

.PHONY: distclean-sphinx sphinx

# Configuration.

SPHINX_BUILD ?= sphinx-build
SPHINX_SOURCE ?= doc
SPHINX_CONFDIR ?=
SPHINX_FORMATS ?= html
SPHINX_DOCTREES ?= $(ERLANG_MK_TMP)/sphinx.doctrees
SPHINX_OPTS ?=

#sphinx_html_opts =
#sphinx_html_output = html
#sphinx_man_opts =
#sphinx_man_output = man
#sphinx_latex_opts =
#sphinx_latex_output = latex

# Helpers.

sphinx_build_0 = @echo " SPHINX" $1; $(SPHINX_BUILD) -N -q
sphinx_build_1 = $(SPHINX_BUILD) -N
sphinx_build_2 = set -x; $(SPHINX_BUILD)
sphinx_build = $(sphinx_build_$(V))

define sphinx.build
$(call sphinx_build,$1) -b $1 -d $(SPHINX_DOCTREES) $(if $(SPHINX_CONFDIR),-c $(SPHINX_CONFDIR)) $(SPHINX_OPTS) $(sphinx_$1_opts) -- $(SPHINX_SOURCE) $(call sphinx.output,$1)

endef

define sphinx.output
$(if $(sphinx_$1_output),$(sphinx_$1_output),$1)
endef

# Targets.

ifneq ($(wildcard $(if $(SPHINX_CONFDIR),$(SPHINX_CONFDIR),$(SPHINX_SOURCE))/conf.py),)
docs:: sphinx
distclean:: distclean-sphinx
endif

help::
	$(verbose) printf "%s\n" "" \
		"Sphinx targets:" \
		"  sphinx      Generate Sphinx documentation." \
		"" \
		"ReST sources and 'conf.py' file are expected in directory pointed by" \
		"SPHINX_SOURCE ('doc' by default). SPHINX_FORMATS lists formats to build (only" \
		"'html' format is generated by default); target directory can be specified by" \
		'setting sphinx_$${format}_output, for example: sphinx_html_output = output/html' \
		"Additional Sphinx options can be set in SPHINX_OPTS."

# Plugin-specific targets.

sphinx: $(if $(IS_APP),,venv)
	$(foreach F,$(SPHINX_FORMATS),$(call sphinx.build,$F))

distclean-sphinx:
	$(gen_verbose) rm -rf $(filter-out $(SPHINX_SOURCE),$(foreach F,$(SPHINX_FORMATS),$(call sphinx.output,$F)))


.PHONY: apps-docs

clean-docs::
	$(gen_verbose) rm -rf $(sphinx_html_output)

venv: venv/bin/activate

venv/bin/activate: requirements.txt
	test -d venv || virtualenv venv
	venv/bin/pip install -U setuptools
	venv/bin/pip install -Ur requirements.txt
	touch venv/bin/activate

VENV_ACTIVATE=. venv/bin/activate

clean-venv:
	$(gen_verbose) rm -rf venv

ifneq ($(ALL_APPS_DIRS),)

define docs_app_target
apps-docs-$1:
	@$(MAKE) -C $1 docs IS_APP=1
clean-apps-docs-$1:
	@$(MAKE) -C $1 clean-docs IS_APP=1
endef

$(foreach app,$(ALL_APPS_DIRS),$(eval $(call docs_app_target,$(app))))

apps-docs: $(addprefix apps-docs-,$(ALL_APPS_DIRS))
clean-apps-docs: $(addprefix clean-apps-docs-,$(ALL_APPS_DIRS))

ifeq ($(IS_APP),)
docs:: apps-docs
clean-docs:: clean-apps-docs
endif

endif

clean:: clean-docs
distclean:: clean-venv
