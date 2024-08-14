git checkout -b fix-patches
git merge development
./restore-vanilla-linux.sh
cd linux-files

for patch in ../patches/damiandudycz/*.patch; do 
	patch_name=$(basename $patch)

	patch -p1 -d . < $patch

        find . -name "*.orig" -exec rm {} \;
	git add .
	git diff --relative --cached . > ../patches/damiandudycz/$patch_name

	git add ../patches/damiandudycz/$patch_name
	git commit -m "Add kernel patch: $patch_name"

done

git diff development -- ../patches/damiandudycz

git switch development

git merge --squash fix-patches

git branch -D fix-patches
