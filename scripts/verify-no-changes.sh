{
    git update-index --refresh
    git diff-files --name-only
    git ls-files --others --exclude-standard
} | tee /tmp/dirty
diff /tmp/dirty /dev/null
