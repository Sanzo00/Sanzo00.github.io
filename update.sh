commit=$1
if [ "$commit" = "" ];
then commit=":pencil: Update content"
fi
echo $commit
git add -A
git commit -m "$commit"
git push origin hexo
