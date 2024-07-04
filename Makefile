.default: help

help:
	@echo 'This Makefile contains generation (update-* targets) and verification (verify-* targets) targets. Run all updates and verifications with `make all`.'

all: update-translations update-licenses verify-translations verify-workflows verify-swiftlint verify-no-changes

update-translations:
	lane translations generate -i resources/translations/translations.csv -o Powercast/Assets/Translations.swift -t ios -m 3 -k 1 \
		-c "4 Powercast/Assets/Translations/da.lproj/Localizable.strings" \
		-c "4 Powercast/Assets/Translations/da.lproj/InfoPlist.strings" \
		-c "3 Powercast/Assets/Translations/en-GB.lproj/Localizable.strings" \
		-c "3 Powercast/Assets/Translations/en-GB.lproj/InfoPlist.strings" \
		-c "3 Powercast/Assets/Translations/Base.lproj/Localizable.strings" \
		-c "3 Powercast/Assets/Translations/Base.lproj/InfoPlist.strings"

update-licenses:
	sh resources/update-licenses.sh

verify-translations:
	@find . -name "*.strings" -exec grep -Hin '= "";' {} \; | tee /tmp/missing
	@test -s /tmp/missing && exit 1 || true

verify-workflows:
	find .github/workflows -type f -name \*.yml | xargs -I {} echo action-validator --verbose {} | sh -ex

verify-swiftlint:
	swiftlint --strict --config .swiftlint.ci.yml --config .swiftlint.yml

verify-no-changes:
	@git diff --quiet --exit-code || (echo 'Error: Workplace is dirty:'; git status; exit 1)
