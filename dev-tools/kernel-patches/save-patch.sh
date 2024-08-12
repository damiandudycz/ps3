patch_name="$1"
git add .
cd linux-files
git diff --relative --cached . > ../patches/damiandudycz/$path_name
cd ..
git add .
git commit -m "Add linux patch $patch_name"
