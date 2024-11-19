# this assumes you have an ssh key added to github for both push and signing at ~/.ssh/id_rsa.pub
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_rsa.pub

echo "$(git config --get user.email) namespaces=\"git\" $(cat ~/.ssh/id_rsa.pub)" >> ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

git config --global commit.gpgsign true
git config --global tag.gpgsign true
