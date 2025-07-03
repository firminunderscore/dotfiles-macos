# ----- ENVIRONMENT -----
# Fish shell configuration for interactive sessions
if status is-interactive
    # Initialize Starship prompt and Zoxide for directory navigation
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source
end

# Remove fish greeting message
set -g fish_greeting

# Remove Alt+e binding
bind --erase --preset \ee

# Set language
export LANG="en_US.UTF-8"

# ----- EDITORS -----
# Default editors configuration
export EDITOR=/opt/homebrew/bin/hx
# Export VISUAL=/opt/homebrew/bin/zed

# ----- MANUAL PAGER -----
# Custom pager for man pages using Bat for syntax highlighting
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ----- ALIASES -----
# Shell-related aliases
alias fishconfig="$EDITOR ~/.config/fish/config.fish" # Open fish config
alias starconfig="$EDITOR ~/.config/starship.toml" # Open Starship config
alias zelconfig="$EDITOR ~/.config/zellij/config.kdl" # Open Zellij config
alias reload='echo -e "\033[0;1;33mReloading ..." &&\
  source ~/.config/fish/config.fish &&\
  echo -e "\033[0;1;33mReloaded !"' # Reload fish config
alias sudoedit="sudo $EDITOR" # Edit files with sudo
alias sudoexit="sudo -k" # Reset sudo timestamp
alias dis="disown (jobs -p)" # Disown background jobs
alias dup="docker-compose up -d"
alias dupdate="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once"
alias ddown="docker-compose down"
alias dsp="docker system prune -a"
alias tm="zellij" # Start Zellij
alias tml="zellij list-sessions" # List Zellij sessions
alias tmd="zellij delete-all-sessions -f" # Delete all Zellij sessions
alias hcs="history clear-session && clear" # History clear session
alias readme_edit="open -a marktext README.md" # Edit README in MarkText

# Function to wait for a command to finish executing
function waitcmd
    if test (count $argv) -ne 1
        echo "Usage: waitcmd <command>"
        return 1
    end

    while true
        set pid (pidof $argv[1]) # Get the process ID of the command

        if test -n "$pid"
            return 0 # Command is still running
        end

        sleep 1
    end
end

# ----- GIT ALIASES -----
# Shortcuts for common Git commands
alias gs="git status" # Git status
alias gf="git fetch --prune" # Git fetch with pruning
alias gl="git log --graph --all" # Git log with graph
alias go="onefetch" # Display repository info
alias glc="git shortlog -ne" # List contributors
alias gb='git branch -avv' # List branches
alias gu="gitup ." # Open Gitup
alias gc-="git checkout -" # Quickly switch to the previous branch
alias gda="git diff *" # Git Diff all files
alias gz="lazygit"
alias gurl="gh repo view --web"

set -gx fzf_git_log_opts --preview='git show {1} | delta' # Set Delta for FZF Git Log

# git clone
function clone
    if test (count $argv) -lt 1
        echo "Usage: clone <repo> [target_directory]"
        return 1
    end

    set repo $argv[1]

    if test (count $argv) -ge 2
        set target $argv[2]
        git clone git@github.com:$repo.git $target
        cd $target
    else
        git clone git@github.com:$repo.git
    end
end
# git pull
function gp # g(it) p(ull)
    set branch (git rev-parse --abbrev-ref HEAD)
    git branch --set-upstream-to=origin/$branch $branch
    git pull
end

# Function to add, commit, and push in one command with upstream if needed
function acp # a(dd) c(ommit) p(ush)
    git add .
    git commit

    echo "Press y to push"
    read -l push
    if test "$push" = y
        set branch (git rev-parse --abbrev-ref HEAD)

        # Check if the local branch has an upstream
        if not git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null
            git push -u origin $branch
        else
            git push
        end
    end
end

# Function to checkout to given branch and create it if not exists
function gc --wraps='git branch -avv'
    if test (count $argv) -eq 0
        echo "Usage: gc <branch-name>"
        return 1
    end

    set branch_name $argv[1]

    # Check if the branch exists
    if git rev-parse --verify $branch_name >/dev/null 2>&1
        echo "Switching to existing branch '$branch_name'..."
        git checkout $branch_name
    else
        echo "Branch '$branch_name' does not exist. Creating and switching to it..."
        git checkout -b $branch_name

        echo "Press y to push new branch"
        read -l push
        if test "$push" = y
            git push --set-upstream origin $branch_name
        end
    end
end

# Function to delete both a local and remote Git branch
function gdb --wraps='git branch' --description 'Delete both local and remote git branch'
    if test (count $argv) -eq 0
        echo "Usage: gbd <branch-name>"
        return 1
    end

    set branch_name $argv[1]

    # Check if the local branch exists
    if git rev-parse --verify $branch_name >/dev/null 2>&1
        echo "Deleting local branch '$branch_name'..."
        git branch -d $branch_name
    else
        echo "Local branch '$branch_name' does not exist."
    end

    # Check if the remote branch exists
    if git ls-remote --exit-code --heads origin $branch_name >/dev/null 2>&1
        echo "Deleting remote branch '$branch_name'..."
        git push origin --delete $branch_name
    else
        echo "Remote branch '$branch_name' does not exist."
    end
end

# Function to force reset to HEAD with confirmation
function ff # f(orfait)
    echo -e "\033[0;1;31mAre you sure you want to FF? (y/n)"
    read -l -n 1 -P "Press y to confirm and kill yourself: " response
    if test "$response" = y
        git reset --hard HEAD
        echo -e "\033[0;1;32mSuccesfully FFed!"
    else
        echo -e "\033[0;1;33mFF canceled. Good luck!"
    end
    echo -e "\033[0m"
end

# Function to show git commits conventions
function git_conv
    # First part: Display the Git Commit Conventions Table
    nu -c '
    print "🧾 Git Commit Conventions Table"
        
    let data = [
        { "Commit Type": "🎉 Initialization", "Keyword (type)": "init", "Description": "Project start or module initialization" }
        { "Commit Type": "✨ New Feature", "Keyword (type)": "feat", "Description": "Adding a new feature" }
        { "Commit Type": "🐛 Bug Fix", "Keyword (type)": "fix", "Description": "Fixing a bug" }
        { "Commit Type": "📚 Documentation", "Keyword (type)": "docs", "Description": "Changes made only to documentation" }
        { "Commit Type": "🎨 Formatting", "Keyword (type)": "style", "Description": "Formatting, indentation, spaces, etc. (no code logic modification)" }
        { "Commit Type": "🔄 Refactoring", "Keyword (type)": "refactor", "Description": "Refactoring code without adding or fixing functionality" }
        { "Commit Type": "⏳ Performance", "Keyword (type)": "perf", "Description": "Improving performance" }
        { "Commit Type": "🧪 Tests", "Keyword (type)": "test", "Description": "Adding or modifying tests" }
        { "Commit Type": "🚧 Build", "Keyword (type)": "build", "Description": "Changes affecting the build system or dependencies" }
        { "Commit Type": "🔧 Configuration", "Keyword (type)": "chore", "Description": "Maintenance tasks, non-source code changes (e.g: updating build tools)" }
        { "Commit Type": "⏪ Revert", "Keyword (type)": "revert", "Description": "Reverting a previous commit" }
        { "Commit Type": "❌ Deletion", "Keyword (type)": "chore or refactor", "Description": "Deleting obsolete code, unnecessary files, or features" }
    ]

    # Display the Git Commit Conventions Table
    $data | table
    '

    # Second part: Display Best Practices
    nu -c '
    print "🔑 Best Practices for Commit Messages:"

    let best_practices = [
        "Use present tense (e.g: adds instead of added).",
        "Be concise but descriptive in your message.",
        "Start with an action verb (e.g: adds, fixes, refactors, etc.).",
        "Don\'t forget to explain the why behind the change if necessary (for more complex commits).",
        "Avoid using imperative. Write messages as a description (not like commands).",
        "Limit the subject line to 50 characters for readability."
    ]
    
    # Display the Best Practices
    $best_practices | each {|msg| echo $msg}
    '

    # Third part: Example Section
    nu -c '
    print "📝 Examples of Commit Messages:"

    let examples = [
        "✨ feat: add user login functionality",
        "🐛 fix: correct password hashing issue",
        "📚 docs: update README with setup instructions",
        "🎨 style: format login component",
        "🔄 refactor: extract auth logic into separate service",
        "🧪 test: add unit tests for login validation",
        "❌ chore: remove unused login helper functions"
    ]

    $examples | each {|example| echo $example}
    '
end

function git_tags
    echo "🧹 Deleting all local Git tags..."
    for tag in (git tag)
        git tag -d $tag
    end

    echo "🔄 Fetching and pruning remote tags..."
    git fetch --prune --tags

    echo "✅ Local tags now fully synced with remote."
end

# ----- PYTHON ENVIRONMENT -----
alias python="ipython"
alias ruff="ruff format"
alias jup_clean="rmd /Users/alexian/Library/Jupyter/ && rmd ~/.jupyter/"

# Function to initialize a Python virtual environment
function venvinit
    # Create virtual environment
    python3 -m venv .venv

    # Activate virtual environment
    source .venv/bin/activate.fish

    # Install and upgrade basic packages
    pip install --upgrade pip
    pip install ipython

    # iPyKernel
    echo -e "\033[0;1;33mDo you want to setup Python kernel? (y/n)\033[0m"
    read -l setup_kernel

    if test $setup_kernel = y
        pip install ipykernel
        python -m ipykernel install --user --display-name "Python (venv)"
    else
        echo -e "\033[0;1;31mSkipping Python kernel setup.\033[0m"
    end

    # Ask user about installing requirements
    if test -f "requirements.txt"
        echo -e "\033[0;1;33mrequirements.txt found. Do you want to install dependencies? (y/n)\033[0m"
        read -l install_deps

        if test $install_deps = y
            echo -e "\033[0;1;32mInstalling dependencies from requirements.txt...\033[0m"
            pip install -r requirements.txt
        else
            echo -e "\033[0;1;31mSkipping dependency installation.\033[0m"
        end
    else
        echo -e "\033[0;1;31mNo requirements.txt found.\033[0m"
    end

    # Final message
    echo -e "\033[0;1;32mInitialized!\033[0m"
end

# Function to activate the virtual environment
function venvstart
    # Check if .venv exists
    if test -d ".venv"
        source .venv/bin/activate.fish
        echo -e "\033[0;1;32mVenv Activated!\033[0m"
    else
        echo -e "\033[0;1;31mNo venv found. Initializing...\033[0m"
        venvinit
    end
end

# Function to deactivate the virtual environment
function venvstop
    # Check if .venv exists
    if test -d ".venv"
        deactivate
        echo -e "\033[0;1;32mVenv Deactivated!\033[0m"
    else
        echo -e "\033[0;1;31mNo venv found. \033[0m"
    end
end

# Function to remove the virtual environment
function venvremove
    # Check if .venv exists
    if test -d ".venv"
        # Check if the 'deactivate' command is available
        if type -q deactivate
            venvstop
        end

        rm -rf .venv
        echo -e "\033[0;1;32mVenv and related files removed successfully!\033[0m"
    else
        echo -e "\033[0;1;31mNo venv found to remove.\033[0m"
    end
end

# Function to clean Python cache and bytecode
function pyclean
    find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
    rm -rf .ruff_cache
    rm -rf .ropeproject
    rm -rf dist
    rm -rf build
end

# ----- PIPX -----
# Add PipX to the PATH
set PATH $PATH /Users/alexian/.local/bin

# ----- FILE NAVIGATION & MANAGEMENT -----
# Aliases for file management commands
alias lal="eza -al --icons --git --group-directories-first" # List all files in list format
alias ll="eza -l --icons --git --group-directories-first" # List files in list format
alias ls="eza --icons --git --group-directories-first" # List files
alias lt="eza -TL 3 --icons --group-directories-first" # Tree
alias fzf="fzf --style full --border --preview 'bat --color=always --style=numbers --line-range=:500 {}'" # FZF with Bat
alias zz="cd .." # Go up one directory
alias gdus="sudo gdu-go /" # Disk usage
alias gdu="gdu-go" # Directory files sizes
alias of="open -a Finder ." # Open current directory in Finder
alias rmd="rm -rfvI" # Remove files/directories with confirmation
alias dl="aria2c -x 16 -s 16 -k 1M --file-allocation=none --console-log-level=warn $argv[1]"
alias tmp="z /tmp"
alias backup="~/.backup/backup.sh"
abbr -a cp 'cp -R'
abbr -a - 'cd -'
abbr -a ln 'ln -s'
abbr -a mkdir 'mkdir -p'

# Abbreviations for commonly used commands
abbr -a cat bat # Use bat instead of cat
abbr -a cd z # Use z for cd
abbr -a grep rg # Use rg instead of grep

# Function to create and change into a new directory
function mkcd
    mkdir $argv[1]
    cd $argv[1]
end

# Function to create tmp file
function mktmp
    if test (count $argv) -lt 1
        echo "Usage: mktmp <filename>"
        return 1
    end
    touch /tmp/$argv[1]
    hx /tmp/$argv[1]
end

# ----- SSH -----
abbr -a rsync 'rsync -razvhP' # Rsync with progress, archive, compress, verbose, and human-readable

# ----- INFORMATION COMMANDS -----
# Abbreviations and aliases for information retrieval
abbr -a -g neo fastfetch # Fastfetch system information
alias weather="curl wttr.in" # Fetch weather information
alias info="system_profiler SPSoftwareDataType" # Get system information
alias freq="sudo powermetrics 2> /dev/null | rg 'frequency'" # Check CPU frequency
alias watt="sudo powermetrics 2> /dev/null | rg 'Combined Power'" # Check Power Consumption
alias codeinfo="scc --no-cocomo" # Code counter
alias asitop="sudo asitop" # Asitop
alias trip="sudo trip" # Trippy

# Cheat.sh
function cheat
    curl cheat.sh/$argv[1] | bat
end

# ----- MISCELLANEOUS -----
# Miscellaneous command aliases
alias g++="g++ -std=c++20" # C++ compiler
alias hostedit="sudo $EDITOR /private/etc/hosts" # Edit hosts file
alias khostedit="sudo $EDITOR ~/.ssh/known_hosts" # Edit known hosts
alias ssh_config_edit="$EDITOR ~/.ssh/config" # Edit SSH config
alias cam='ffplay -f avfoundation -framerate 30 -i "0"' # Start webcam
alias speedtest="networkquality" # Run network speed test
alias sed="sd"
alias regex="grex"
alias ifc="ifconfig |grep 'inet ' -B4"

# Function to send text over http
function serve_text
    echo (string join " " $argv) >/tmp/text.txt
    python3 -m http.server 80 -d /tmp
    rm /tmp/text.txt
end

# Function to fix permissions on known_hosts
function fixkhost
    sudo chown alexian ~/.ssh/known_hosts
    chmod 600 ~/.ssh/known_hosts
end

# Function to highlight code using Silicon
function codecp
    set -l highlight_args

    for arg in $argv[2..-1]
        set highlight_args $highlight_args --highlight-lines $arg
    end

    silicon --from-clipboard --to-clipboard \
        --shadow-color '#555' --shadow-blur-radius 30 \
        --background '#fff' \
        --font 'Hack Nerd Font' \
        -l $argv[1] $highlight_args
end

# Function to display a clock using tty-clock
function clock
    clear
    tty-clock -ScDB
    clear
end

# Function for a humorous output
function rose
    echo -e "Roses are \033[91mred"
    echo -e "\033[39mViolets are \033[94mblue"
    echo -e "\033[39mMissing semicolon on line 32"
end

# Function to convert video with hardware encoding
function convert
    if test (count $argv) -ne 2
        echo "Usage: convert <input> <output>"
        return 1
    end

    ffmpeg -i $argv[1] -c:v h264_videotoolbox $argv[2]
end

# ----- ADB COMMANDS -----
# Aliases for Android Debug Bridge commands
alias adbc="adb connect $argv[1]" # Connect to ADB
alias adbd="adb disconnect" # Disconnect from ADB

abbr -a -g adbs scrcpy # Abbreviation for scrcpy

# Open YouTube link via ADB
alias cradb="adb shell am start 'https://ww.youtube.com/watch?v=LDU_Txk06tM'"
alias braketv="adb shell monkey -v $argv[1] -s 100" # Run ADB command to app

# ----- MPV -----
# Function to play media with MPV
function play
    mpv $argv[1] --pause --cache=no &
    disown (jobs -p)
    exit
end

# ----- SYSTEM COMMANDS -----
# System-related aliases and functions
alias undamage="sudo xattr -rd com.apple.quarantine $argv[1]" # Remove quarantine attribute
alias permreset="tccutil reset $argv[1] $argv[2]" # Reset permissions
alias mountdmg="hdiutil attach $argv[1]" # Mount DMG file
alias gatekeeper="sudo spctl --master-$argv[1]" # Manage Gatekeeper

# ----- SERVER UPDATE -----
function serverupdate
    ssh prod-server
    ssh vpn
    ssh utils
    ssh media
    ssh dashboard
    ssh proxy

    read -l -P "Do you want to connect to mc? (y/n): " confirm_mc
    if test "$confirm_mc" = y
        ssh mc /root/update.sh
    end

    ssh vm-iut
    ssh rpi
end

# ----- HOMEBREW -----
# Aliases for Homebrew package manager
alias bd="brew info" # Show detailed information
alias bs="brew search" # Search for packages
alias bsi="brew list | rg $argv[1]" # Search installed packages

# Function to list installed packages based on type
function bl
    if test "$argv[1]" = all
        brew list --versions
    else if test "$argv[1]" = c
        brew list --cask --versions
    else if test "$argv[1]" = f
        brew list --formula --versions
    else
        echo "Usage: bl [all|c|f]"
    end
end

# Function to install a package and cleanup
function bi
    brew install $argv
    find "$(brew --prefix)/Caskroom" -type f -name '*.pkg' -delete
    brew cleanup --prune=all -s
end

# Function to uninstall a package and cleanup
function br
    brew uninstall --zap $argv --force
    brew cleanup --prune=all -s
    brew autoremove
end

# Function to cleanup unused packages
function bc
    brew cleanup --prune=all -s
    brew autoremove
    find "$(brew --prefix)/Caskroom" -type f -name '*.pkg' -delete
end

# Function to update Homebrew and installed packages
function update
    set -l bold "\033[1m"
    set -l green "\033[0;32m"
    set -l red "\033[0;31m"
    set -l reset "\033[0m"

    # Start update process
    echo -e "$bold----- Updating Homebrew -----$reset"
    brew update
    echo -e "$green✅ Homebrew updated successfully!$reset"

    # Show outdated packages
    echo -e "$bold----- Outdated Packages -----$reset"
    brew outdated

    # Upgrade packages
    echo -e "$bold----- Upgrading Packages -----$reset"
    brew upgrade
    echo -e "$green✅ Packages upgraded!$reset"

    # Cleanup
    echo -e "$bold----- Cleaning Up -----$reset"
    brew cleanup --prune=all -s
    echo -e "$green✅ Cleanup successful!$reset"

    # Auto-remove unnecessary packages
    echo -e "$bold----- Auto-Removing Unnecessary Packages -----$reset"
    brew autoremove
    echo -e "$green✅ Auto-remove completed!$reset"

    # Update Fisher plugins
    echo -e "$bold----- Updating Fisher Plugins -----$reset"
    fisher update
    echo -e "$green✅ Fisher plugins updated!$reset"

    # Upgrade Bun
    echo -e "$bold----- Upgrading Bun -----$reset"
    bun upgrade
    echo -e "$green✅ Bun upgraded!$reset"

    echo -e "$bold----- Upgrading gh extensions -----$reset"
    gh extension upgrade --all
    echo -e "$green✅ GH extensions upgraded!$reset"

    echo -e "$bold----- Upgrading PIPX Modules -----$reset"
    pipx upgrade-all
    echo -e "$green✅ Python modules upgraded!$reset"

    # Final success message
    echo -e "$bold$green----- Update Successful! -----$reset"
end

# ----- BUN -----
# Set up Bun package manager
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Added by LM Studio CLI tool (lms)
set -gx PATH $PATH /Users/alexian/.lmstudio/bin

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# ----- NVM 
set -gx NVM_DIR "$HOME/.nvm"
if test -s "/opt/homebrew/opt/nvm/nvm.sh"
    source "/opt/homebrew/opt/nvm/nvm.sh"
end
if test -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
end

echo ""
fastfetch

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/firmin/.lmstudio/bin
# End of LM Studio CLI section


# pnpm
set -gx PNPM_HOME "/Users/firmin/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
