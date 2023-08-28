{lib, vscode-utils}:

with vscode-utils;

{
  shan.code-settings-sync = buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "code-settings-sync";
      publisher = "shan";
      version = "3.4.3";
      sha256 = "0wdlf34bsyihjz469sam76wid8ylf0zx2m1axnwqayngi3y8nrda";
    };

    meta = with lib; {
      changelog = "https://marketplace.visualstudio.com/items/shan.code-settings-sync/changelog";
      description = "Synchronize Settings, Snippets, Themes, File Icons, Launch, Keybindings, Workspaces and Extensions Across Multiple Machines Using GitHub Gist.";
      downloadPage = "https://marketplace.visualstudio.com/items?itemName=shan.code-settings-sync";
      homepage = "https://github.com/shanalikhan/code-settings-sync";
      license = licenses.mit;
      # maintainers = [ dlo9 ];
    };
  };
}
