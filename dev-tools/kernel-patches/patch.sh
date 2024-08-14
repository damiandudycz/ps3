patch -p1 -d linux-files < $1
find linux-files -name "*.orig" -exec rm {} \;
git add linux-files
