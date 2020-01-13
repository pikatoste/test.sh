# Adapt github's  README.md to jekyll
ORIG="$1"
sed -i -e 's/```shell script$/```bash/' -e '/BADGE-START/,/BADGE-END/{//!d}' $ORIG
