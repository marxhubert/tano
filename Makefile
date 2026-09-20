# Site helpers. The landing page lives under site/ and is published by
# .github/workflows/pages.yml.

.PHONY: config preview hooks

# Write site/config.json from the template and the pubspec.yaml version.
config:
	./tool/site_config.sh

# Preview the site, with a configuration fresh from the current version.
preview: config
	@echo "Serving site/ on http://127.0.0.1:8777/"
	@python3 -m http.server 8777 --directory site --bind 127.0.0.1

# Point git at the versioned hooks (run once per clone).
hooks:
	git config core.hooksPath .githooks
	@echo "Hooks installed from .githooks/"
