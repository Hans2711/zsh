$KEYCHAIN_PATH -q --nogui $HOME/.ssh/hans.diesing@netigo.de.key
$KEYCHAIN_PATH -q --nogui $HOME/.ssh/hp@diesing.pro.key
KEYCHAIN=$(find $HOME/.keychain/ -name "*-sh")
source $KEYCHAIN -sh
