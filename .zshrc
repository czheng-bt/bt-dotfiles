# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# autoload -U +X bashcompinit && bashcompinit
# autoload -U +X compinit && compinit

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source "${ZSH}/oh-my-zsh.sh"

export EDITOR='vim'
export GPG_TTY=$(tty)

# Get directory of current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

############################
# Path
############################
src='/build/czheng/repos'
repo_harbor="$src/Harbor"
laser="$repo_harbor/Laser"
clang="$laser/ContinuousDelivery/ClangTidy"
build_dir='/build/czheng/build/'
export BUILDDIR="/build/czheng/build"
export PATH="$PATH:/opt/rh/gcc-toolset-11/root/bin:/usr/local/bazel/bin"
export CONAN_HOME="/build/czheng/.conan2"

############################
# General
############################
alias c="clear"
alias r="reload"
alias reload="source ~/.zshrc"
alias zshconfig="code ~/.zshrc"

function goto() {
    dir=$1
    lowercase_dir=${dir:l} # lowercase

    REPOS=(
        "Harbor"
        "PillarRoot"
        "SaltMaster"
    )

    if (($REPOS[(Ie)$dir])); then
        cd "$src/$dir"
    elif [[ "$lowercase_dir" == "notes" ]]; then
        cd "/build/czheng/repos/bt-notes"
    elif [[ "$lowercase_dir" == "build" ]]; then
        cd "/build/czheng/build"
    else
        echo "Unknown destination $dir"
    fi
}

############################
# Git/Gerrit
############################
alias gl="git pull"
alias gcoc="gco candidate"
alias checkout="hydra ci checkout"
alias co="hydra ci checkout"
alias push="hydra ci push"
alias review="hydra ci review"
alias rebase="hydra ci rebase"
alias ur="hydra ci ur"

############################
# Python
############################
function restore_python() {
    git restore **/setup.py
    git restore **/*.req
}

function test_python() {
    project=$1
    hydra ci build Python --flags="-p ${project}"
    hydra ci analyze Python --flags="-p ${project}"
    hydra ci test Python --flags="-f -p ${project}"
}

############################
# Laser
############################
function cmake-d() {
    pushd "$build_dir" > /dev/null
    CC=clang CXX=clang++ cmake -DCTAGS_ENABLED=False -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -GNinja $laser
    popd > /dev/null
}
function cmake-r() {
    pushd "$build_dir" > /dev/null
    CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=Release -DCTAGS_ENABLED=False -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -GNinja $laser
    popd > /dev/null
}

function build() {
    arg1=$1
    # NUM=16
    pushd "$build_dir" > /dev/null
    if [[ "$arg1" == "-j*" ]]; then
        ninja -k 0 $@
    else
        ninja -k 100 $@
    fi
    popd > /dev/null
}

alias b="build"
alias build-d="cmake-d && build"

# clang tidy. Runs over files in current git commit. Use -d <Num> to add all files from Num commits back to now
PYTHON="/build/czheng/build/laser_venv/bin/python"
alias tidy='taskset -c 0-31 $PYTHON $clang/parallel-clang-tidy-diff.py -p $build_dir'

GDB="/opt/rh/gcc-toolset-11/root/bin/gdb"
IP="10.10.168.103"
PORT=18252
alias hard-start="sudo $build_dir/HighFrequency/BT.HighFrequency/BT.HighFrequency.Service.Win.UI/BT.HighFrequency.Service --ip=$IP --port=$PORT -c Laser -i czheng"
alias debug-start="sudo $GDB --args $build_dir/HighFrequency/BT.HighFrequency/BT.HighFrequency.Service.Win.UI/BT.HighFrequency.Service --ip=$IP --port=$PORT -c Laser -i czheng"
alias soft-start="sudo hydra instance start Laser czheng --soft-only"


# This gives autocomplete for your shell when building targets
_ninjaComplete()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(ninja -t targets all | grep -v / | awk -F ':' '{print $1}')" -- $cur))
}
complete -F _ninjaComplete ninja

function get_executable() {
    target="$1"
    BT="BT."
    target=${target#"$BT"}
    executable="BT.${target//.//}/BT.$target"
    echo "$executable"
}

function test() {
    target="$1"
    executable=`get_executable "$target"`
    echo "Running test $executable" "${@:2}"

    pushd "$build_dir" > /dev/null
    sudo $executable "${@:2}"
    popd > /dev/null
}

function debug() {
    target="$1"
    executable=`get_executable "$target"`
    echo "Debugging test $executable" "${@:2}"

    pushd "$build_dir" > /dev/null
    sudo $GDB $executable "${@:2}"
    popd > /dev/null
}

function clean() {
    local flag="${1:-""}"
    pushd "$build_dir" > /dev/null
    # if [ "$1" == "-n" ]; then
    #     ninja clean
    # fi
    rm -r ./*
    popd > /dev/null
}

function clean-hydra-build() {
    pushd /build/czheng > /dev/null
    files=(
        BT.* API build.ninja* BuildScripts CMakeCache.txt CMakeFiles cmake_install.cmake compile_commands.json Contracts
        *.cmake DartConfiguration.tcl Examples Hephaestus HighFrequency Testing
        TestResults
    ) # ThirdPartycompile_commands.json*
    for file in "${files[@]}"; do
        rm -rf $file
    done
    popd > /dev/null
}

function format() {
    should_popd=false
    if [[ "$PWD" != "$repo_harbor" ]]; then
        pushd "$repo_harbor" > /dev/null
        should_popd=true
    fi
    clang-format -i `git diff --name-only --diff-filter=d HEAD~1 | grep -v 'ThirdParty' | grep -v 'CMakeLists.txt' | grep -i '\.h\|\.cpp'`
    if [[ "$should_popd" == "true" ]]; then
        popd > /dev/null
    fi
}

############################
# Salt
############################
alias salt-call-local='sudo salt-call --local --file-root /build/czheng/repos/SaltMaster --pillar-root /build/czheng/repos/PillarRoot'
alias sc='sudo salt-call'
alias sclocal='salt-call-local'
highstate() {
    if [[ "$1" == "-l" ]]; then
        echo "Applying local highstate"
        salt-call-local state.highstate
    else
        echo "Applying highstate"
        sudo salt-call state.highstate
    fi
}
alias hs='highstate'
alias hsl='highstate -l'

############################
# Bazel
############################

install_bazelisk() {
    VERSION="$1"
    if [ -z "$VERSION" ]; then
        echo "Usage: install_bazelisk <version>"
        return 1
    fi
    URL="https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64"
    echo "Downloading Bazelisk version ${VERSION} from ${URL}"
    sudo curl -L -o /usr/local/bazel/bin/bazelisk "${URL}"
    sudo chmod +x /usr/local/bazel/bin/bazelisk
    sudo ln -sf /usr/local/bazel/bin/bazelisk /usr/local/bazel/bin/bazel
}

############################
# Misc
############################

DOTNET_CLI_TELEMETRY_OPTOUT=1

if [ -f "/build/czheng/repos/dotfiles/source.sh" ]; then
    source "/build/czheng/repos/dotfiles/source.sh"
fi

hosts() {
    echo "chisrvdevtst020"
}

############################
# Local scripts
############################
if [ -f "$HOME/zshrc-local.sh" ]; then
    source "$HOME/zshrc-local.sh"
fi

############################
# End
############################

if [ -z "$DISPLAY" ]; then
  PROMPT="%{$fg[green]%}%n%{$reset_color%}@%{$fg[cyan]%}%m%{$reset_color%} ${PROMPT}"
fi
