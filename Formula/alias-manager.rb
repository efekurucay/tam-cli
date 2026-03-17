cask "alias-manager" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/efekurucay/tam-cli/releases/download/v#{version}/AliasManager.dmg"
  name "AliasManager"
  desc "Visual manager for zsh terminal aliases"
  homepage "https://github.com/efekurucay/tam-cli"

  depends_on macos: ">= :sonoma"

  app "AliasManager.app"

  zap trash: [
    "~/.config/alias-manager",
  ]
end
