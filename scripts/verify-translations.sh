find . -name "*.strings" -exec grep -Hin '= "";' {} \; | tee /tmp/missing
diff /tmp/missing /dev/null
