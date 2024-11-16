alias zshrc="nvim ~/dotfiles/.zshrc"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc

eval "$(/opt/homebrew/bin/brew shellenv)"

plugins=(
  git
  bundler
  dotenv
  macos
  kubectl
  z
  zsh-autosuggestions
)
source ~/.oh-my-zsh/oh-my-zsh.sh

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
