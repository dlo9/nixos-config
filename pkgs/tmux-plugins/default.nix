
{fetchFromGitHub,
  tmuxPlugins
  }:

with tmuxPlugins;

{
  tmux-themepack = mkTmuxPlugin {
    pluginName = "tmux-themepack";
    rtpFilePath = "themepack.tmux";
    version = "unstable-2022-05-18";
    src = fetchFromGitHub {
      owner = "jimeh";
      repo = "tmux-themepack";
      rev = "7c59902f64dcd7ea356e891274b21144d1ea5948";
      sha256 = "1kl93d0b28f4gn1knvbb248xw4vzb0f14hma9kba3blwn830d4bk";
    };
  };
}

