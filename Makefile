.PHONY: all clean test

COMPOSE_RUN = docker compose run --rm --quiet-pull

all: update-translations update-licenses verify-translations verify-workflows verify-dependabot verify-make verify-editorconfig verify-swiftlint verify-no-changes

help:
	@echo 'This Makefile contains generation (update-* targets) and verification (verify-* targets) targets. Run all updates and verifications with `make all`.'

clean:
	docker compose down --rmi all --remove-orphans

update-translations:
	$(COMPOSE_RUN) lane translations generate -i resources/translations/translations.csv -o Powercast/Assets/Translations.swift -t ios -m 3 -k 1 \
		-c "4 Powercast/Assets/Translations/da.lproj/Localizable.strings" \
		-c "4 Powercast/Assets/Translations/da.lproj/InfoPlist.strings" \
		-c "3 Powercast/Assets/Translations/en-GB.lproj/Localizable.strings" \
		-c "3 Powercast/Assets/Translations/en-GB.lproj/InfoPlist.strings" \
		-c "3 Powercast/Assets/Translations/Base.lproj/Localizable.strings" \
		-c "3 Powercast/Assets/Translations/Base.lproj/InfoPlist.strings"

update-licenses:
	$(COMPOSE_RUN) builder sh scripts/update-licenses.sh

# does not work yet - see https://github.com/krzysztofzablocki/Sourcery/issues/1382
# update-sourcery:
# 	$(COMPOSE_RUN) sourcery

verify-translations:
	$(COMPOSE_RUN) builder sh -x scripts/verify-translations.sh

verify-workflows:
	$(COMPOSE_RUN) jsonschema sh -ec 'find .github/workflows -type f -name \*.yml | xargs -I {} echo check-jsonschema --builtin-schema vendor.github-workflows {} | sh -ex'

verify-dependabot:
	$(COMPOSE_RUN) jsonschema check-jsonschema --builtin-schema vendor.dependabot .github/dependabot.yml

verify-make:
	$(COMPOSE_RUN) makelint

verify-editorconfig:
	$(COMPOSE_RUN) eclint

verify-swiftlint:
	$(COMPOSE_RUN) swiftlint swiftlint --strict --config .swiftlint.ci.yml --config .swiftlint.yml

verify-no-changes:
	$(COMPOSE_RUN) builder sh scripts/verify-no-changes.sh
