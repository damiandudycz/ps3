patch_name="$1"
git add linux-files
cd linux-files
git diff --relative --cached . > ../patches/damiandudycz/$path_name.patch
cd ..
git add patches/damiandudycz/$path_name.patch
git commit -m "Add kernel patch: $patch_name"
