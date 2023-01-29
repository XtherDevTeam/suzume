echo "reXscript installer (Linux)"
echo "Installer will install reXscript to ~/.rex automatically..."
cd /temp
echo "Cloning repository"
git clone https://github.com/XtherDevTeam/suzume.git
cd suzume
git submodule init; git submodule update; git submodule sync; cd rexStdlib; git submodule init; git submodule update; git submodule sync; cd ..
echo "Building project...Make sure you've installed openssl via the package manager on your machine"
make dist_prod
mkdir -p ~/.rex
cp -r dist_prod/* ~/.rex/
echo "Adding reXscript to PATH..."
echo "export PATH=~/.rex:\$PATH" >> ~/.bashrc
echo "If installer can't add reXscript to PATH, please execute the following command in terminal by yourself."
echo ""
echo "export PATH=~/.rex:\$PATH"
echo "source ~/.bashrc"
echo ""
echo "Cleaning temporary files..."
cd ..
rm -rf suzume
echo "Done!"
source ~/.bashrc