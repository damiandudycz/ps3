patch_name="$1"
git add linux-files
cd linux-files
git diff --relative --cached . > ../patches/damiandudycz/$path_name
cd ..
git add patches/damiandudycz/$path_name
git commit -m "Add kernel patch: $patch_name"
