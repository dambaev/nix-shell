let
  pkgs = (import <nixpkgs> {}); # first, load the nixpkgs with system-wide overlays
  remotemake = pkgs.writeScriptBin "remotemake" ''
    PWD=$(pwd)
    DIFF=$(git diff --relative)
    COMMIT=$(git log | head -n 1 | awk '{ print $2}')
    echo "$DIFF" | ssh -A $REMOTEMAKEHOST "cd $PWD; LOCAL_COMMIT=\$(git log | head -n 1 | awk '{print \$2}'); echo "LOCAL GIT COMMIT \$LOCAL_COMMIT"; \
      git diff --relative | patch -p1 -R;\
      if [ "\$LOCAL_COMMIT" != "$COMMIT" ]; then\
        git pull;\
        git checkout $COMMIT;\
      fi;\
      patch -p1;\
      rmake;\
      "
  '';
  tmux-sessionizer = pkgs.writeScriptBin "tmux-sessionizer" ''
    if [[ $# -eq 1 ]]; then
      selected=$1
    else
      selected=$(find ~/.config /data/devel /data/share/work26 /data/share/work26/tgbot /data/devel/op-energy/oe-account-service /data/devel/op-energy-blockspan-service /data/devel/nixos -mindepth 1 -maxdepth 1 -type d | fzf)
    fi

    if [[ -z $selected ]]; then
      exit 0
    fi

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
      tmux new-session -s $selected_name -c $selected
      exit 0
    fi

    if ! tmux has-session -t=$selected_name 2> /dev/null; then
      tmux new-session -ds $selected_name -c $selected
    fi

    if [[ -z $TMUX ]]; then
      tmux attach -t $selected_name
    else
      tmux switch-client -t $selected_name
    fi
  '';
  shell = pkgs.stdenv.mkDerivation {
    name = "shell";
    buildInputs
      =  with pkgs; [ remotemake
                      neovim
                      git
                      tmux fzf tmux-sessionizer
                      ripgrep
                    ];
  };

in shell
