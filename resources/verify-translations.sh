find . -name "*.strings" -exec grep -Hin '= "";' {} \; | tee /tmp/missing
test -s /tmp/missing && exit 1 || true