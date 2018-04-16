
#!/bin/bash -ex
# This script is used to fetch the complete source for android build

echo "Start fetching the source for android build"

if [ -z "$WORKSPACE" ];then
    WORKSPACE=$PWD
    echo "Setting WORKSPACE to $WORKSPACE"
fi

if [ -z "$android_builddir" ];then
    android_builddir=$WORKSPACE/android_build
    echo "Setting android_builddir to $android_builddir"
fi

#git clone https://gerrit-google.tuna.tsinghua.edu.cn/git-repo tuna-git-repo
git clone https://aosp.tuna.tsinghua.edu.cn/git-repo tuna-git-repo

if [ ! -d "$android_builddir" ]; then
    # Create android build dir if it does not exist.
    mkdir $android_builddir
    cd $android_builddir
	$WORKSPACE/tuna-git-repo/repo init -u https://source.codeaurora.org/external/imx/imx-manifest.git -b imx-android-oreo -m imx-o8.1.0_1.2.0_8qxp-prc.xml
      rc=$?
      if [ "$rc" != 0 ]; then
         echo "---------------------------------------------------"
         echo "-----Repo Init failure"
         echo "---------------------------------------------------"
         return 1
      fi
fi

# Don't Delete .repo directory and hidden files
#rm -rf $android_builddir/.??*

cat << EOF > $WORKSPACE/0001-change-to-local-aosp.patch
diff --git a/aosp-O8.1.0-1.1.0.xml b/aosp-O8.1.0-1.1.0.xml
index 746466a..1f756c4 100644
--- a/aosp-O8.1.0-1.1.0.xml
+++ b/aosp-O8.1.0-1.1.0.xml
@@ -2,7 +2,7 @@
 <manifest>
 
   <remote  name="aosp"
-           fetch="https://android.googlesource.com/"
+           fetch="https://aosp.tuna.tsinghua.edu.cn/"
            review="https://android-review.googlesource.com/" />
   <default revision="refs/tags/android-8.1.0_r1"
            remote="aosp"
EOF

cd $android_builddir/.repo/manifests
git apply $WORKSPACE/0001-change-to-local-aosp.patch
rm $WORKSPACE/0001-change-to-local-aosp.patch

cd $android_builddir

$WORKSPACE/tuna-git-repo/repo sync
      rc=$?
      if [ "$rc" != 0 ]; then
         echo "---------------------------------------------------"
         echo "------Repo sync failure"
         echo "---------------------------------------------------"
         return 1
      fi

# Copy all the proprietary packages to the android build folder

cd $WORKSPACE/imx-o8.1.0_1.2.0_8qxp-prc
cp -r vendor/nxp $android_builddir/vendor
cp -r EULA.txt $android_builddir
cp -r SCR* $android_builddir

cd $android_builddir

# unset variables

unset android_builddir
unset WORKSPACE

echo "Android source is ready for the build"
