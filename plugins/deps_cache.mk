# The sed rule inside converts a git URL like https://github.com/basho/lager to 'github_com_basho_lager'
override define dep_fetch_git
	$(eval CACHE_NAME := $(shell echo "$(call dep_repo,$(1))" | sed -r 's/^[^:\/\/]*:\/\///g;s/[:/.]+/_/g')) \
	if [ ! -d ~/.gitcaches/$(CACHE_NAME).reference ]; then \
		git clone -q --mirror  $(call dep_repo,$(1)) ~/.gitcaches/$(CACHE_NAME).reference; \
	fi; \
	git clone -q -n --reference ~/.gitcaches/$(CACHE_NAME).reference $(call dep_repo,$(1)) $(DEPS_DIR)/$(call dep_name,$(1)); \
	cd $(DEPS_DIR)/$(call dep_name,$(1)) && git checkout -q $(call dep_commit,$(1)) && git repack -a -q && rm .git/objects/info/alternates;
endef

override define dep_fetch_hex
	mkdir -p $(ERLANG_MK_TMP)/hex $(DEPS_DIR)/$1; \
	$(eval TAR_PATH := $(ERLANG_MK_TMP)/hex/$1.tar) \
	$(eval DEP_TAR_FILENAME := $1-$(strip $(word 2,$(dep_$1))).tar) \
	$(eval REMOTE_PATH := https://repo.hex.pm/tarballs/$(DEP_TAR_FILENAME)) \
	$(eval CACHE_PATH := ~/.gitcaches/$(DEP_TAR_FILENAME)) \
	$(if $(wildcard $(CACHE_PATH)), \
		$(eval ETAG := $(shell md5sum $(CACHE_PATH))) \
		curl -H "if-none-match: $(ETAG)" -Lf$(if $(filter-out 0,$(V)),,s)o $(CACHE_PATH) $(REMOTE_PATH); \
		,curl -Lf$(if $(filter-out 0,$(V)),,s)o $(CACHE_PATH) $(REMOTE_PATH); \
	) \
	cp $(CACHE_PATH) $(TAR_PATH); \
	tar -xOf $(TAR_PATH) contents.tar.gz | tar -C $(DEPS_DIR)/$1 -xzf -;
endef
