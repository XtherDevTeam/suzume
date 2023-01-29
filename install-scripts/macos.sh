echo "reXscript installer (macOS)"
echo "Installer will install reXscript to ~/.rex automatically..."
cd $TMPDIR
echo "Cloning repository"
git clone https://github.com/XtherDevTeam/suzume.git
cd suzume
git submodule init; git submodule update; git submodule sync; cd rexStdlib; git submodule init; git submodule update; git submodule sync; cd ..
echo "Building project...Make sure you've installed brew"
brew install openssl
make dist_prod
mkdir -p ~/.rex
cp -r dist_prod/* ~/.rex/
echo "Adding reXscript to PATH..."
echo "export PATH=~/.rex:\$PATH" >> ~/.zshrc
echo "Cleaning temporary files..."
cd ..
rm -rf suzume
echo "Done!"
source ~/.zshrc