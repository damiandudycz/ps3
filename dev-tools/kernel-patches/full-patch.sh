for patch in patches/New/*.patch; do 
	patch -p1 -d linux-files < $patch
done
