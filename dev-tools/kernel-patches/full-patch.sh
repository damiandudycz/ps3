for patch in patches/damiandudycz/*.patch; do 
	patch -p1 -d linux-files < $patch
done
