# The sed rule inside converts a git URL like https://github.com/basho/lager to 'github_com_basho_lager'
override define dep_fetch_git
	$(eval CACHE_NAME := $(shell echo "$(call dep_repo,$(1))" | sed -r 's/^[^:\/\/]*:\/\///g;s/[:/.]+/_/g')) \
	if [ ! -d ~/.gitcaches/$(CACHE_NAME).reference ]; then \
		git clone -q --mirror  $(call dep_repo,$(1)) ~/.gitcaches/$(CACHE_NAME).reference; \
	fi; \
	git clone -q -n --reference ~/.gitcaches/$(CACHE_NAME).reference $(call dep_repo,$(1)) $(DEPS_DIR)/$(call dep_name,$(1)); \
	cd $(DEPS_DIR)/$(call dep_name,$(1)) && git checkout -q $(call dep_commit,$(1)) && git repack -a -q && rm .git/objects/info/alternates;
endef
