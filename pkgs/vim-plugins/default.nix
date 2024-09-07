{
  fetchFromGitHub,
  vimUtils,
}:
with vimUtils; {
  vim-central = buildVimPlugin rec {
    name = "vim-central";
    pname = name;
    src = fetchFromGitHub {
      owner = "her";
      repo = "central.vim";
      rev = "802b20d0e6400f8b81079ca696153be5b50cc65a";
      sha256 = "0j11dch1m48pf26dwzsxcz5x36k5fj4awa8hq4fl20gh3gzfylj4";
    };
  };

  # Requires python support in vim
  vimania-uri-rs = buildVimPlugin rec {
    name = "vimania-uri-rs";
    pname = name;
    src = fetchFromGitHub {
      owner = "sysid";
      repo = "vimania-uri-rs";
      rev = "v1.1.1";
      sha256 = "sha256-V0bJnAUHo8nnEo+x1M7nEbNXafRbdwlm+A6MMQyqf30=";
    };
  };

  vim-yadi = buildVimPlugin rec {
    name = "vim-yadi";
    pname = name;
    src = fetchFromGitHub {
      owner = "timakro";
      repo = "vim-yadi";
      rev = "d868366707bfc966f856347828607f92bc5cd9fb";
      sha256 = "0c34y7w31vg2qijprhnd0dakmqasaiflrkh54iv8shn79l7cvhsm";
    };
  };

  coc-biome = buildVimPlugin rec {
    name = "coc-biome";
    pname = name;
    src = fetchFromGitHub {
      owner = "fannheyward";
      repo = "coc-biome";
      rev = "11d04a8e535780a1132307d701eb005bc08792e5";
      sha256 = "sha256-yC9Y2WbaXZAVuQjtoG6sETDEjovDoFIEHMk+rBGm0G0=";
    };
  };

  coc-sh = buildVimPlugin rec {
    name = "coc-sh";
    pname = name;
    src = fetchFromGitHub {
      owner = "josa42";
      repo = "coc-sh";
      rev = "c3d808d7a0bf20d999c2ab84f899133cfdfaffc2";
      sha256 = "0lvjbi7bfx8r7l10hlysq8jjfb2wv70db3gsqf67rc1d15p4n7nm";
    };
  };

  coc-docker = buildVimPlugin rec {
    name = "coc-docker";
    pname = name;
    src = fetchFromGitHub {
      owner = "josa42";
      repo = "coc-docker";
      rev = "fd949be7a0178c6d5358f6ccf4f6b73c6fc181b2";
      sha256 = "0b4hk85wvvzd5a628kp2lk45bxqj7q2fsrhfkvd36cnhwc262zml";
    };
  };
}
