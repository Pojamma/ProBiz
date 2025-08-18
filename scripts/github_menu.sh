#!/bin/bash

# GitHub Interactive Menu Script
# A comprehensive tool for Git/GitHub operations

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Function to print header
print_header() {
    clear
    print_color "CYAN" "=================================================="
    print_color "CYAN" "           GitHub Interactive Menu"
    print_color "CYAN" "=================================================="
    echo
}

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_color "RED" "Error: Git is not installed. Please install Git first."
        exit 1
    fi
}

# Function to check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to load environment variables from .env file
load_env() {
    if [ -f ".env" ]; then
        export $(cat .env | sed 's/#.*//g' | xargs)
    fi
}

# Function to get GitHub credentials from .env
get_github_credentials() {
    load_env
    if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_TOKEN" ]; then
        return 0
    fi
    return 1
}

# Function to get Git user config from .env
get_git_config() {
    load_env
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        return 0
    fi
    return 1
}

# Function to check if repository has commits
has_commits() {
    git rev-parse --verify HEAD >/dev/null 2>&1
}

# Global variable to track menu level
MENU_LEVEL="main"

# Function to pause and wait for user input
pause() {
    print_color "YELLOW" "\nPress any key to continue..."
    read -n 1 -s
}

# Function to get user input with prompt and handle empty input
get_input() {
    local prompt="$1"
    local var_name="$2"
    local allow_empty="${3:-false}"
    
    while true; do
        if [ "$allow_empty" = "true" ]; then
            printf "${BLUE}%s (Enter for previous menu): ${NC}" "$prompt"
        else
            printf "${BLUE}%s${NC}: " "$prompt"
        fi
        read -r input
        
        if [ -z "$input" ] && [ "$allow_empty" = "true" ]; then
            if [ "$MENU_LEVEL" = "main" ]; then
                print_color "GREEN" "Thanks for using GitHub Interactive Menu!"
                exit 0
            else
                return 1  # Go back to previous menu
            fi
        elif [ -z "$input" ] && [ "$allow_empty" = "false" ]; then
            print_color "RED" "Input cannot be empty. Please try again."
            continue
        else
            eval "$var_name=\"\$input\""
            return 0
        fi
    done
}

# Function to get yes/no confirmation
confirm() {
    local prompt="$1"
    while true; do
        printf "${YELLOW}%s (y/n): ${NC}" "$prompt"
        read -r yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) print_color "RED" "Please answer yes or no.";;
        esac
    done
}

# Repository Management Functions
clone_repository() {
    print_header
    print_color "GREEN" "=== Clone Repository ==="
    echo
    get_input "Enter repository URL or username/repository" repo_url
    
    if [[ "$repo_url" == *"/"* ]] && [[ "$repo_url" != *"github.com"* ]] && [[ "$repo_url" != *"git@"* ]]; then
        repo_url="https://github.com/${repo_url}.git"
    fi
    
    get_input "Enter directory name (press Enter for default)" dir_name
    
    if [ -z "$dir_name" ]; then
        git clone "$repo_url"
    else
        git clone "$repo_url" "$dir_name"
    fi
    
    if [ $? -eq 0 ]; then
        print_color "GREEN" "Repository cloned successfully!"
    else
        print_color "RED" "Failed to clone repository."
    fi
    pause
}

init_repository() {
    print_header
    print_color "GREEN" "=== Initialize New Repository ==="
    echo
    
    if [ -d ".git" ]; then
        print_color "YELLOW" "This directory is already a git repository."
        pause
        return
    fi
    
    git init
    
    if confirm "Create initial commit with README.md?"; then
        echo "# $(basename "$PWD")" > README.md
        git add README.md
        git commit -m "Initial commit"
        print_color "GREEN" "Repository initialized with README.md!"
    else
        print_color "GREEN" "Repository initialized!"
    fi
    
    if confirm "Add remote origin?"; then
        get_input "Enter remote repository URL" remote_url
        git remote add origin "$remote_url"
        print_color "GREEN" "Remote origin added!"
    fi
    pause
}

# Basic Git Operations
git_status() {
    print_header
    print_color "GREEN" "=== Repository Status ==="
    echo
    git status
    pause
}

git_add() {
    print_header
    print_color "GREEN" "=== Add Files ==="
    echo
    
    print_color "BLUE" "Choose what to add:"
    echo "1. Add all files (git add .)"
    echo "2. Add specific file(s)"
    echo "3. Add by pattern"
    echo "4. Add all modified files only"
    echo "5. Back to main menu"
    echo
    if ! get_input "Enter choice (1-5)" choice true; then
        return
    fi
    
    case $choice in
        1)
            git add .
            print_color "GREEN" "All files added to staging area!"
            ;;
        2)
            if ! get_input "Enter file name(s) separated by spaces" files; then
                return
            fi
            git add $files
            print_color "GREEN" "Files added to staging area!"
            ;;
        3)
            if ! get_input "Enter pattern (e.g., *.txt)" pattern; then
                return
            fi
            git add $pattern
            print_color "GREEN" "Files matching pattern added!"
            ;;
        4)
            git add -u
            print_color "GREEN" "All modified files added!"
            ;;
        5)
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    pause
}

# Unstage Files - FIXED VERSION
git_unstage() {
    print_header
    print_color "GREEN" "=== Unstage Files ==="
    echo
    
    # Show staged files
    print_color "BLUE" "Currently staged files:"
    git diff --cached --name-only
    echo
    
    if [ -z "$(git diff --cached --name-only)" ]; then
        print_color "YELLOW" "No files are currently staged."
        pause
        return
    fi
    
    print_color "BLUE" "Choose what to unstage:"
    echo "1. Unstage all files"
    echo "2. Unstage specific file(s)"
    echo "3. Back to main menu"
    echo
    if ! get_input "Enter choice (1-3)" choice true; then
        return
    fi
    
    case $choice in
        1)
            if has_commits; then
                git reset HEAD
            else
                # For repositories with no commits, use git reset without HEAD
                git reset
            fi
            print_color "GREEN" "All files unstaged!"
            ;;
        2)
            if ! get_input "Enter file name(s) separated by spaces" files; then
                return
            fi
            if has_commits; then
                git reset HEAD $files
            else
                # For repositories with no commits
                git reset $files
            fi
            print_color "GREEN" "Files unstaged!"
            ;;
        3)
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    pause
}

git_commit() {
    print_header
    print_color "GREEN" "=== Commit Changes ==="
    echo
    
    # Show status first
    git status --short
    echo
    
    get_input "Enter commit message" commit_msg
    
    if [ -z "$commit_msg" ]; then
        print_color "RED" "Commit message cannot be empty."
        pause
        return
    fi
    
    git commit -m "$commit_msg"
    
    if [ $? -eq 0 ]; then
        print_color "GREEN" "Changes committed successfully!"
    else
        print_color "RED" "Commit failed. Make sure you have staged changes."
    fi
    pause
}

git_push() {
    print_header
    print_color "GREEN" "=== Push Changes ==="
    echo
    
    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$current_branch" ]; then
        print_color "RED" "Not in a git repository or no commits yet."
        pause
        return
    fi
    
    print_color "BLUE" "Current branch: $current_branch"
    echo
    
    # Check for GitHub credentials in .env
    if get_github_credentials; then
        print_color "GREEN" "✓ GitHub credentials found in .env file"
        print_color "BLUE" "Username: $GITHUB_USERNAME"
        print_color "YELLOW" "When Git prompts for password, use your GitHub token (not your GitHub password)"
        echo
    else
        print_color "YELLOW" "No .env file found with GitHub credentials."
        print_color "YELLOW" "Create a .env file with:"
        print_color "CYAN" "GITHUB_USERNAME=your_username"
        print_color "CYAN" "GITHUB_TOKEN=your_personal_access_token"
        echo
    fi
    
    # Check if remote URL uses HTTPS and might need authentication setup
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ "$remote_url" == https://github.com/* ]]; then
        print_color "YELLOW" "Note: Using HTTPS remote. Use your GitHub token as password when prompted."
        echo
    fi
    
    if confirm "Push to origin/$current_branch?"; then
        git push origin "$current_branch"
        if [ $? -eq 0 ]; then
            print_color "GREEN" "Changes pushed successfully!"
        else
            print_color "RED" "Push failed."
            if [[ "$remote_url" == https://github.com/* ]]; then
                echo
                print_color "YELLOW" "Authentication Error Solution:"
                if get_github_credentials; then
                    print_color "CYAN" "When Git prompts for credentials, use:"
                    print_color "BLUE" "Username: $GITHUB_USERNAME"
                    print_color "BLUE" "Password: $GITHUB_TOKEN (your personal access token)"
                else
                    print_color "YELLOW" "GitHub no longer supports password authentication."
                    print_color "YELLOW" "Create a .env file or use option 19 for authentication help."
                fi
                echo
            fi
            print_color "YELLOW" "Trying to set upstream..."
            git push -u origin "$current_branch"
        fi
    else
        get_input "Enter remote name" remote_name
        get_input "Enter branch name" branch_name
        git push "$remote_name" "$branch_name"
    fi
    pause
}

git_pull() {
    print_header
    print_color "GREEN" "=== Pull Changes ==="
    echo
    
    current_branch=$(git branch --show-current 2>/dev/null)
    print_color "BLUE" "Current branch: $current_branch"
    echo
    
    if confirm "Pull from origin/$current_branch?"; then
        git pull origin "$current_branch"
    else
        get_input "Enter remote name" remote_name
        get_input "Enter branch name" branch_name
        git pull "$remote_name" "$branch_name"
    fi
    
    if [ $? -eq 0 ]; then
        print_color "GREEN" "Changes pulled successfully!"
    else
        print_color "RED" "Pull failed. Check for conflicts."
    fi
    pause
}

# Branch Management
branch_operations() {
    MENU_LEVEL="branch"
    print_header
    print_color "GREEN" "=== Branch Operations ==="
    echo
    
    print_color "BLUE" "Choose operation:"
    echo "1. List branches"
    echo "2. Create new branch"
    echo "3. Switch branch"
    echo "4. Create and switch to new branch"
    echo "5. Delete branch"
    echo "6. Merge branch"
    echo "7. Back to main menu"
    echo
    if ! get_input "Enter choice (1-7)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            echo
            print_color "CYAN" "Local branches:"
            git branch
            echo
            print_color "CYAN" "Remote branches:"
            git branch -r
            ;;
        2)
            if ! get_input "Enter new branch name" branch_name; then
                branch_operations
                return
            fi
            git branch "$branch_name"
            print_color "GREEN" "Branch '$branch_name' created!"
            ;;
        3)
            git branch
            echo
            if ! get_input "Enter branch name to switch to" branch_name; then
                branch_operations
                return
            fi
            git checkout "$branch_name"
            ;;
        4)
            if ! get_input "Enter new branch name" branch_name; then
                branch_operations
                return
            fi
            git checkout -b "$branch_name"
            print_color "GREEN" "Created and switched to branch '$branch_name'!"
            ;;
        5)
            git branch
            echo
            if ! get_input "Enter branch name to delete" branch_name; then
                branch_operations
                return
            fi
            if confirm "Are you sure you want to delete branch '$branch_name'?"; then
                git branch -d "$branch_name"
            fi
            ;;
        6)
            current_branch=$(git branch --show-current)
            git branch
            echo
            if ! get_input "Enter branch name to merge into $current_branch" branch_name; then
                branch_operations
                return
            fi
            git merge "$branch_name"
            ;;
        7)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "7" ]; then
        pause
        branch_operations
    fi
}

# History and Logs
git_log() {
    print_header
    print_color "GREEN" "=== Git Log ==="
    echo
    
    print_color "BLUE" "Choose log format:"
    echo "1. Standard log"
    echo "2. One line per commit"
    echo "3. Graph view"
    echo "4. Last N commits"
    echo
    get_input "Enter choice (1-4)" choice
    
    case $choice in
        1)
            git log
            ;;
        2)
            git log --oneline
            ;;
        3)
            git log --graph --oneline --all
            ;;
        4)
            get_input "Enter number of commits to show" num
            git log -n "$num" --oneline
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    pause
}

# NEW: Diff Operations
diff_operations() {
    MENU_LEVEL="diff"
    print_header
    print_color "GREEN" "=== View Differences ==="
    echo
    
    print_color "BLUE" "Choose what to compare:"
    echo "1. Working directory vs staged (what you'd stage with 'git add')"
    echo "2. Staged vs last commit (what you'd commit)"
    echo "3. Working directory vs last commit (all changes)"
    echo "4. Between two commits"
    echo "5. Between branches"
    echo "6. Specific file differences"
    echo "7. Back to main menu"
    echo
    if ! get_input "Enter choice (1-7)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            print_color "CYAN" "Changes in working directory (not staged):"
            git diff
            ;;
        2)
            print_color "CYAN" "Changes staged for commit:"
            git diff --cached
            ;;
        3)
            print_color "CYAN" "All changes since last commit:"
            git diff HEAD
            ;;
        4)
            if ! get_input "Enter first commit (hash or reference)" commit1; then
                diff_operations
                return
            fi
            if ! get_input "Enter second commit (hash or reference)" commit2; then
                diff_operations
                return
            fi
            git diff "$commit1" "$commit2"
            ;;
        5)
            git branch -a
            echo
            if ! get_input "Enter first branch name" branch1; then
                diff_operations
                return
            fi
            if ! get_input "Enter second branch name" branch2; then
                diff_operations
                return
            fi
            git diff "$branch1" "$branch2"
            ;;
        6)
            if ! get_input "Enter file path" file_path; then
                diff_operations
                return
            fi
            print_color "BLUE" "Choose comparison:"
            echo "1. Working vs staged"
            echo "2. Staged vs last commit"
            echo "3. Working vs last commit"
            if ! get_input "Enter choice (1-3)" file_choice; then
                diff_operations
                return
            fi
            case $file_choice in
                1) git diff "$file_path" ;;
                2) git diff --cached "$file_path" ;;
                3) git diff HEAD "$file_path" ;;
            esac
            ;;
        7)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "7" ]; then
        pause
        diff_operations
    fi
}

# NEW: Undo & Recovery Operations
undo_operations() {
    MENU_LEVEL="undo"
    print_header
    print_color "GREEN" "=== Undo & Recovery Operations ==="
    echo
    
    print_color "RED" "⚠️  CAUTION: These operations can permanently delete work!"
    print_color "YELLOW" "Always make sure you understand what each operation does."
    echo
    
    print_color "BLUE" "Choose operation:"
    echo "1. Discard changes in working directory (specific file)"
    echo "2. Discard all changes in working directory"
    echo "3. Undo last commit (keep changes)"
    echo "4. Undo last commit (discard changes)"
    echo "5. Reset to specific commit (keep changes)"
    echo "6. Reset to specific commit (discard changes)"
    echo "7. Revert a commit (create new commit that undoes it)"
    echo "8. Back to main menu"
    echo
    if ! get_input "Enter choice (1-8)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            git status --short
            echo
            if ! get_input "Enter file path to discard changes" file_path; then
                undo_operations
                return
            fi
            if confirm "Are you sure you want to discard changes in '$file_path'?"; then
                git checkout -- "$file_path"
                print_color "GREEN" "Changes discarded for '$file_path'!"
            fi
            ;;
        2)
            git status --short
            echo
            if confirm "Are you sure you want to discard ALL working directory changes?"; then
                git checkout -- .
                print_color "GREEN" "All working directory changes discarded!"
            fi
            ;;
        3)
            if has_commits; then
                if confirm "Undo last commit but keep changes in working directory?"; then
                    git reset --soft HEAD~1
                    print_color "GREEN" "Last commit undone, changes kept!"
                fi
            else
                print_color "RED" "No commits to undo."
            fi
            ;;
        4)
            if has_commits; then
                if confirm "Undo last commit and DISCARD all changes? This cannot be undone!"; then
                    git reset --hard HEAD~1
                    print_color "GREEN" "Last commit undone and changes discarded!"
                fi
            else
                print_color "RED" "No commits to undo."
            fi
            ;;
        5)
            git log --oneline -10
            echo
            if ! get_input "Enter commit hash to reset to" commit_hash; then
                undo_operations
                return
            fi
            if confirm "Reset to '$commit_hash' but keep changes in working directory?"; then
                git reset --soft "$commit_hash"
                print_color "GREEN" "Reset to '$commit_hash', changes kept!"
            fi
            ;;
        6)
            git log --oneline -10
            echo
            if ! get_input "Enter commit hash to reset to" commit_hash; then
                undo_operations
                return
            fi
            if confirm "Reset to '$commit_hash' and DISCARD all changes? This cannot be undone!"; then
                git reset --hard "$commit_hash"
                print_color "GREEN" "Reset to '$commit_hash', changes discarded!"
            fi
            ;;
        7)
            git log --oneline -10
            echo
            if ! get_input "Enter commit hash to revert" commit_hash; then
                undo_operations
                return
            fi
            if confirm "Create a new commit that undoes changes from '$commit_hash'?"; then
                git revert "$commit_hash"
                print_color "GREEN" "Commit '$commit_hash' reverted!"
            fi
            ;;
        8)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "8" ]; then
        pause
        undo_operations
    fi
}

# NEW: Stash Operations
stash_operations() {
    MENU_LEVEL="stash"
    print_header
    print_color "GREEN" "=== Stash Operations ==="
    echo
    
    print_color "BLUE" "Git stash temporarily saves your changes so you can work on something else."
    echo
    
    print_color "BLUE" "Choose operation:"
    echo "1. Stash current changes"
    echo "2. Stash with message"
    echo "3. List all stashes"
    echo "4. Apply latest stash (keep stash)"
    echo "5. Pop latest stash (apply and remove)"
    echo "6. Apply specific stash"
    echo "7. Drop (delete) specific stash"
    echo "8. Show stash contents"
    echo "9. Clear all stashes"
    echo "10. Back to main menu"
    echo
    if ! get_input "Enter choice (1-10)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            if [ -n "$(git status --porcelain)" ]; then
                git stash
                print_color "GREEN" "Changes stashed!"
            else
                print_color "YELLOW" "No changes to stash."
            fi
            ;;
        2)
            if [ -n "$(git status --porcelain)" ]; then
                if ! get_input "Enter stash message" stash_msg; then
                    stash_operations
                    return
                fi
                git stash save "$stash_msg"
                print_color "GREEN" "Changes stashed with message!"
            else
                print_color "YELLOW" "No changes to stash."
            fi
            ;;
        3)
            print_color "CYAN" "Current stashes:"
            git stash list
            ;;
        4)
            if [ -n "$(git stash list)" ]; then
                git stash apply
                print_color "GREEN" "Latest stash applied!"
            else
                print_color "YELLOW" "No stashes available."
            fi
            ;;
        5)
            if [ -n "$(git stash list)" ]; then
                git stash pop
                print_color "GREEN" "Latest stash applied and removed!"
            else
                print_color "YELLOW" "No stashes available."
            fi
            ;;
        6)
            git stash list
            echo
            if [ -n "$(git stash list)" ]; then
                if ! get_input "Enter stash reference (e.g., stash@{0})" stash_ref; then
                    stash_operations
                    return
                fi
                git stash apply "$stash_ref"
                print_color "GREEN" "Stash '$stash_ref' applied!"
            else
                print_color "YELLOW" "No stashes available."
            fi
            ;;
        7)
            git stash list
            echo
            if [ -n "$(git stash list)" ]; then
                if ! get_input "Enter stash reference to drop (e.g., stash@{0})" stash_ref; then
                    stash_operations
                    return
                fi
                if confirm "Are you sure you want to delete '$stash_ref'?"; then
                    git stash drop "$stash_ref"
                    print_color "GREEN" "Stash '$stash_ref' deleted!"
                fi
            else
                print_color "YELLOW" "No stashes available."
            fi
            ;;
        8)
            git stash list
            echo
            if [ -n "$(git stash list)" ]; then
                if ! get_input "Enter stash reference to show (e.g., stash@{0})" stash_ref; then
                    stash_operations
                    return
                fi
                git stash show -p "$stash_ref"
            else
                print_color "YELLOW" "No stashes available."
            fi
            ;;
        9)
            if [ -n "$(git stash list)" ]; then
                if confirm "Are you sure you want to delete ALL stashes?"; then
                    git stash clear
                    print_color "GREEN" "All stashes cleared!"
                fi
            else
                print_color "YELLOW" "No stashes to clear."
            fi
            ;;
        10)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "10" ]; then
        pause
        stash_operations
    fi
}

# Remote Management
remote_operations() {
    MENU_LEVEL="remote"
    print_header
    print_color "GREEN" "=== Remote Operations ==="
    echo
    
    print_color "BLUE" "Choose operation:"
    echo "1. List remotes"
    echo "2. Add remote"
    echo "3. Remove remote"
    echo "4. Fetch from remote"
    echo "5. Back to main menu"
    echo
    if ! get_input "Enter choice (1-5)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            git remote -v
            ;;
        2)
            if ! get_input "Enter remote name" remote_name; then
                remote_operations
                return
            fi
            if ! get_input "Enter remote URL" remote_url; then
                remote_operations
                return
            fi
            git remote add "$remote_name" "$remote_url"
            print_color "GREEN" "Remote '$remote_name' added!"
            ;;
        3)
            git remote -v
            echo
            if ! get_input "Enter remote name to remove" remote_name; then
                remote_operations
                return
            fi
            git remote remove "$remote_name"
            print_color "GREEN" "Remote '$remote_name' removed!"
            ;;
        4)
            git remote -v
            echo
            if ! get_input "Enter remote name to fetch from" remote_name; then
                remote_operations
                return
            fi
            git fetch "$remote_name"
            ;;
        5)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "5" ]; then
        pause
        remote_operations
    fi
}

# GitHub CLI Operations (if available)
github_cli_operations() {
    if ! check_gh_cli; then
        print_color "RED" "GitHub CLI (gh) is not installed."
        print_color "YELLOW" "Install it from: https://cli.github.com/"
        pause
        return
    fi
    
    MENU_LEVEL="github"
    print_header
    print_color "GREEN" "=== GitHub CLI Operations ==="
    echo
    
    print_color "BLUE" "Choose operation:"
    echo "1. Create pull request"
    echo "2. List pull requests"
    echo "3. Create issue"
    echo "4. List issues"
    echo "5. Fork repository"
    echo "6. Create repository"
    echo "7. Repository info"
    echo "8. Back to main menu"
    echo
    if ! get_input "Enter choice (1-8)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            if ! get_input "Enter PR title" pr_title; then
                github_cli_operations
                return
            fi
            if ! get_input "Enter PR body (optional)" pr_body; then
                github_cli_operations
                return
            fi
            if [ -z "$pr_body" ]; then
                gh pr create --title "$pr_title"
            else
                gh pr create --title "$pr_title" --body "$pr_body"
            fi
            ;;
        2)
            gh pr list
            ;;
        3)
            if ! get_input "Enter issue title" issue_title; then
                github_cli_operations
                return
            fi
            if ! get_input "Enter issue body (optional)" issue_body; then
                github_cli_operations
                return
            fi
            if [ -z "$issue_body" ]; then
                gh issue create --title "$issue_title"
            else
                gh issue create --title "$issue_title" --body "$issue_body"
            fi
            ;;
        4)
            gh issue list
            ;;
        5)
            if ! get_input "Enter repository to fork (username/repo)" repo_to_fork; then
                github_cli_operations
                return
            fi
            gh repo fork "$repo_to_fork"
            ;;
        6)
            if ! get_input "Enter repository name" repo_name; then
                github_cli_operations
                return
            fi
            if ! get_input "Enter description (optional)" repo_desc; then
                github_cli_operations
                return
            fi
            if confirm "Make repository public?"; then
                visibility="--public"
            else
                visibility="--private"
            fi
            
            if [ -z "$repo_desc" ]; then
                gh repo create "$repo_name" $visibility
            else
                gh repo create "$repo_name" --description "$repo_desc" $visibility
            fi
            ;;
        7)
            gh repo view
            ;;
        8)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "8" ]; then
        pause
        github_cli_operations
    fi
}

# Quick Actions
quick_commit_push() {
    print_header
    print_color "GREEN" "=== Quick Commit & Push ==="
    echo
    
    git status --short
    echo
    
    if confirm "Add all files and commit?"; then
        get_input "Enter commit message" commit_msg
        if [ -z "$commit_msg" ]; then
            print_color "RED" "Commit message cannot be empty."
            pause
            return
        fi
        
        git add .
        git commit -m "$commit_msg"
        
        if [ $? -eq 0 ]; then
            if confirm "Push to remote?"; then
                current_branch=$(git branch --show-current)
                
                # Check for GitHub credentials and provide guidance
                if get_github_credentials; then
                    print_color "BLUE" "Using credentials from .env: $GITHUB_USERNAME"
                    print_color "YELLOW" "When Git prompts for password, use your GitHub token."
                fi
                
                # Check for HTTPS remote and provide auth guidance
                remote_url=$(git remote get-url origin 2>/dev/null)
                if [[ "$remote_url" == https://github.com/* ]]; then
                    print_color "YELLOW" "Note: If push fails with authentication error, check option 19 for auth help."
                fi
                
                git push origin "$current_branch" 2>/dev/null || {
                    if git push -u origin "$current_branch"; then
                        print_color "GREEN" "Changes committed and pushed with upstream set!"
                    else
                        print_color "RED" "Push failed. Check authentication or use option 19 for help."
                    fi
                    return
                }
                print_color "GREEN" "Changes committed and pushed!"
            else
                print_color "GREEN" "Changes committed!"
            fi
        else
            print_color "RED" "Commit failed."
        fi
    fi
    pause
}

# Repository Information
repo_info() {
    print_header
    print_color "GREEN" "=== Repository Information ==="
    echo
    
    if [ ! -d ".git" ]; then
        print_color "RED" "Not in a git repository."
        pause
        return
    fi
    
    print_color "CYAN" "Repository Status:"
    echo "=================="
    git status --short
    echo
    
    print_color "CYAN" "Current Branch:"
    echo "==============="
    git branch --show-current
    echo
    
    print_color "CYAN" "Recent Commits:"
    echo "==============="
    git log --oneline -5
    echo
    
    print_color "CYAN" "Remotes:"
    echo "========"
    git remote -v
    echo
    
    print_color "CYAN" "Branch Summary:"
    echo "==============="
    git branch -a
    echo
    
    pause
}

# Main Menu
show_menu() {
    print_header
    
    # Display current location and repository info
    current_dir=$(pwd)
    current_dir_name=$(basename "$current_dir")
    
    print_color "CYAN" "Current Location:"
    print_color "BLUE" "  Directory: $current_dir_name"
    print_color "BLUE" "  Full Path: $current_dir"
    
    if [ -d ".git" ]; then
        current_branch=$(git branch --show-current 2>/dev/null)
        remote_url=$(git remote get-url origin 2>/dev/null)
        
        if [ -n "$remote_url" ]; then
            # Extract repository name from URL
            if [[ "$remote_url" == *"github.com"* ]]; then
                repo_name=$(echo "$remote_url" | sed 's/.*github.com[\/:]//g' | sed 's/\.git$//')
                print_color "BLUE" "  Repository: $repo_name"
            else
                print_color "BLUE" "  Repository: $remote_url"
            fi
        else
            print_color "BLUE" "  Repository: Local repository (no remote)"
        fi
        
        if [ -n "$current_branch" ]; then
            print_color "BLUE" "  Branch: $current_branch"
        fi
        
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            print_color "YELLOW" "  Status: ⚠ Uncommitted changes"
        else
            print_color "GREEN" "  Status: ✓ Clean working directory"
        fi
        
        # Check for .env file
        if get_github_credentials; then
            print_color "GREEN" "  Auth: ✓ GitHub credentials found"
        else
            print_color "YELLOW" "  Auth: ⚠ No .env credentials"
        fi
        
        # Check git user config
        if get_git_config; then
            print_color "GREEN" "  Git User: ✓ Configured in .env"
        elif [ -n "$(git config user.name)" ]; then
            print_color "BLUE" "  Git User: $(git config user.name)"
        else
            print_color "YELLOW" "  Git User: ⚠ Not configured"
        fi
    else
        print_color "RED" "  Repository: Not a git repository"
    fi
    
    echo
    print_color "GREEN" "Select an operation (Enter for exit):"
    echo
    print_color "BLUE" "Repository Management:"
    echo "  1.  Clone repository"
    echo "  2.  Initialize new repository"
    echo
    print_color "BLUE" "Basic Operations:"
    echo "  3.  Check status"
    echo "  4.  Add files"
    echo "  5.  Unstage files"
    echo "  6.  Commit changes"
    echo "  7.  Push changes"
    echo "  8.  Pull changes"
    echo
    print_color "BLUE" "Branch Management:"
    echo "  9.  Branch operations"
    echo
    print_color "BLUE" "History & Information:"
    echo "  10. View git log"
    echo "  11. Repository information"
    echo "  12. View differences"
    echo
    print_color "BLUE" "Undo & Recovery:"
    echo "  13. Undo & reset operations"
    echo "  14. Stash operations"
    echo
    print_color "BLUE" "Remote Management:"
    echo "  15. Remote operations"
    echo
    print_color "BLUE" "GitHub Features:"
    echo "  16. GitHub CLI operations"
    echo
    print_color "BLUE" "Configuration:"
    echo "  17. Git user configuration"
    echo "  18. Edit .gitignore"
    echo "  19. Authentication help"
    echo
    print_color "BLUE" "Quick Actions:"
    echo "  20. Quick commit & push"
    echo
    print_color "RED" "  0.  Exit"
    echo
}

# Git Configuration Management
git_config_management() {
    MENU_LEVEL="config"
    print_header
    print_color "GREEN" "=== Git User Configuration ==="
    echo
    
    # Show current git config
    current_name=$(git config user.name 2>/dev/null)
    current_email=$(git config user.email 2>/dev/null)
    
    print_color "CYAN" "Current Git Configuration:"
    if [ -n "$current_name" ]; then
        print_color "BLUE" "  Name: $current_name"
    else
        print_color "RED" "  Name: Not set"
    fi
    
    if [ -n "$current_email" ]; then
        print_color "BLUE" "  Email: $current_email"
    else
        print_color "RED" "  Email: Not set"
    fi
    echo
    
    # Check .env file for git config
    if get_git_config; then
        print_color "CYAN" "Configuration in .env file:"
        print_color "BLUE" "  Name: $GIT_USER_NAME"
        print_color "BLUE" "  Email: $GIT_USER_EMAIL"
        echo
    fi
    
    print_color "BLUE" "Choose operation:"
    echo "1. Set user name and email manually"
    echo "2. Use credentials from .env file"
    echo "3. Update .env file with new credentials"
    echo "4. Set global configuration"
    echo "5. Set local configuration (this repo only)"
    echo "6. Back to main menu"
    echo
    if ! get_input "Enter choice (1-6)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            if ! get_input "Enter your name" user_name; then
                git_config_management
                return
            fi
            if ! get_input "Enter your email" user_email; then
                git_config_management
                return
            fi
            git config user.name "$user_name"
            git config user.email "$user_email"
            print_color "GREEN" "Git configuration updated locally!"
            ;;
        2)
            if get_git_config; then
                git config user.name "$GIT_USER_NAME"
                git config user.email "$GIT_USER_EMAIL"
                print_color "GREEN" "Git configuration updated from .env file!"
            else
                print_color "RED" "No git credentials found in .env file."
                print_color "YELLOW" "Add GIT_USER_NAME and GIT_USER_EMAIL to your .env file."
            fi
            ;;
        3)
            if ! get_input "Enter your name" user_name; then
                git_config_management
                return
            fi
            if ! get_input "Enter your email" user_email; then
                git_config_management
                return
            fi
            
            # Update or create .env file
            if [ -f ".env" ]; then
                # Remove existing git config lines
                sed -i '/^GIT_USER_NAME=/d' .env
                sed -i '/^GIT_USER_EMAIL=/d' .env
            fi
            
            echo "GIT_USER_NAME=$user_name" >> .env
            echo "GIT_USER_EMAIL=$user_email" >> .env
            
            # Also set git config
            git config user.name "$user_name"
            git config user.email "$user_email"
            
            print_color "GREEN" ".env file updated and git configuration set!"
            ;;
        4)
            if ! get_input "Enter your name" user_name; then
                git_config_management
                return
            fi
            if ! get_input "Enter your email" user_email; then
                git_config_management
                return
            fi
            git config --global user.name "$user_name"
            git config --global user.email "$user_email"
            print_color "GREEN" "Global git configuration updated!"
            ;;
        5)
            if ! get_input "Enter your name" user_name; then
                git_config_management
                return
            fi
            if ! get_input "Enter your email" user_email; then
                git_config_management
                return
            fi
            git config --local user.name "$user_name"
            git config --local user.email "$user_email"
            print_color "GREEN" "Local git configuration updated!"
            ;;
        6)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "6" ]; then
        pause
        git_config_management
    fi
}

auth_help() {
    print_header
    print_color "GREEN" "=== GitHub Authentication Help ==="
    echo
    
    print_color "YELLOW" "GitHub no longer supports password authentication for Git operations."
    print_color "YELLOW" "Here are your authentication options:"
    echo
    
    print_color "CYAN" "Option 1 - Personal Access Token with .env file (Recommended):"
    print_color "BLUE" "  1. Go to GitHub.com"
    print_color "BLUE" "  2. Settings → Developer settings → Personal access tokens → Tokens (classic)"
    print_color "BLUE" "  3. Generate new token (classic)"
    print_color "BLUE" "  4. Select 'repo' scope for full repository access"
    print_color "BLUE" "  5. Create a .env file in your project with:"
    print_color "GREEN" "     GITHUB_USERNAME=your_username"
    print_color "GREEN" "     GITHUB_TOKEN=your_personal_access_token"
    print_color "BLUE" "  6. Use the token as your password when Git prompts"
    echo
    
    print_color "CYAN" "Option 2 - SSH Keys:"
    print_color "BLUE" "  1. Generate SSH key: ssh-keygen -t ed25519 -C \"your_email@example.com\""
    print_color "BLUE" "  2. Add to SSH agent: ssh-add ~/.ssh/id_ed25519"
    print_color "BLUE" "  3. Copy public key: cat ~/.ssh/id_ed25519.pub"
    print_color "BLUE" "  4. Add to GitHub: Settings → SSH and GPG keys → New SSH key"
    print_color "BLUE" "  5. Change remote URL to SSH format"
    echo
    
    print_color "CYAN" "Option 3 - GitHub CLI:"
    print_color "BLUE" "  1. Install GitHub CLI: https://cli.github.com/"
    print_color "BLUE" "  2. Run: gh auth login"
    print_color "BLUE" "  3. Follow the prompts to authenticate"
    echo
    
    current_remote=$(git remote get-url origin 2>/dev/null)
    if [[ "$current_remote" == https://github.com/* ]]; then
        repo_path=$(echo "$current_remote" | sed 's/https:\/\/github.com\///' | sed 's/\.git$//')
        ssh_url="git@github.com:${repo_path}.git"
        print_color "CYAN" "Quick Fix for Current Repository:"
        print_color "BLUE" "  To switch this repo to SSH, run:"
        print_color "GREEN" "  git remote set-url origin $ssh_url"
        echo
    fi
    
    if confirm "Would you like to create a .env file template?"; then
        if [ ! -f ".env" ]; then
            cat > .env << EOF
# GitHub credentials for git operations
GITHUB_USERNAME=your_username_here
GITHUB_TOKEN=your_personal_access_token_here

# Git user configuration
GIT_USER_NAME=Your Full Name
GIT_USER_EMAIL=your.email@example.com
EOF
            print_color "GREEN" ".env file created! Please edit it with your credentials."
            print_color "YELLOW" "Don't forget to add .env to your .gitignore file!"
        else
            print_color "YELLOW" ".env file already exists."
        fi
    fi
    
    if confirm "Would you like to switch current repository to SSH?"; then
        if [[ "$current_remote" == https://github.com/* ]]; then
            repo_path=$(echo "$current_remote" | sed 's/https:\/\/github.com\///' | sed 's/\.git$//')
            ssh_url="git@github.com:${repo_path}.git"
            git remote set-url origin "$ssh_url"
            print_color "GREEN" "Remote URL updated to SSH format!"
            print_color "YELLOW" "Make sure you have SSH keys set up in GitHub."
        else
            print_color "RED" "Current remote is not a GitHub HTTPS URL."
        fi
    fi
    
    pause
}

# GitIgnore Editor
edit_gitignore() {
    MENU_LEVEL="gitignore"
    print_header
    print_color "GREEN" "=== Edit .gitignore File ==="
    echo
    
    if [ ! -f ".gitignore" ]; then
        if confirm ".gitignore file doesn't exist. Create it?"; then
            touch .gitignore
            print_color "GREEN" ".gitignore file created!"
        else
            pause
            return
        fi
    fi
    
    print_color "BLUE" "Current .gitignore contents:"
    echo "=========================="
    cat .gitignore
    echo "=========================="
    echo
    
    print_color "BLUE" "Choose action:"
    echo "1. Edit with nano"
    echo "2. Add common patterns"
    echo "3. Add .env to .gitignore"
    echo "4. Back to main menu"
    echo
    if ! get_input "Enter choice (1-4)" choice true; then
        MENU_LEVEL="main"
        return
    fi
    
    case $choice in
        1)
            if command -v nano &> /dev/null; then
                nano .gitignore
                print_color "GREEN" ".gitignore file updated!"
            else
                print_color "RED" "Nano is not installed. Install it or use another editor."
            fi
            ;;
        2)
            print_color "BLUE" "Common .gitignore patterns:"
            echo "1. Node.js project"
            echo "2. Python project"  
            echo "3. Java project"
            echo "4. General development"
            echo "5. Custom pattern"
            echo
            if ! get_input "Choose pattern set (1-5)" pattern_choice; then
                edit_gitignore
                return
            fi
            
            case $pattern_choice in
                1)
                    cat >> .gitignore << EOF

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
dist/
build/
EOF
                    ;;
                2)
                    cat >> .gitignore << EOF

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.env
venv/
env/
ENV/
EOF
                    ;;
                3)
                    cat >> .gitignore << EOF

# Java
*.class
*.log
*.ctxt
.mtj.tmp/
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar
hs_err_pid*
target/
.env
EOF
                    ;;
                4)
                    cat >> .gitignore << EOF

# General Development
.env
.env.local
.env.*.local
*.log
.DS_Store
.vscode/
.idea/
*.swp
*.swo
*~
.tmp/
temp/
EOF
                    ;;
                5)
                    if ! get_input "Enter custom pattern to add" custom_pattern; then
                        edit_gitignore
                        return
                    fi
                    echo "$custom_pattern" >> .gitignore
                    ;;
            esac
            print_color "GREEN" "Patterns added to .gitignore!"
            ;;
        3)
            if grep -q "^\.env$" .gitignore; then
                print_color "YELLOW" ".env is already in .gitignore"
            else
                echo ".env" >> .gitignore
                print_color "GREEN" ".env added to .gitignore!"
            fi
            ;;
        4)
            MENU_LEVEL="main"
            return
            ;;
        *)
            print_color "RED" "Invalid choice."
            ;;
    esac
    
    if [ "$choice" != "4" ]; then
        pause
        edit_gitignore
    fi
}

main() {
    check_git
    
    while true; do
        MENU_LEVEL="main"
        show_menu
        if ! get_input "Enter your choice (0-20)" choice true; then
            print_color "GREEN" "Thanks for using GitHub Interactive Menu!"
            exit 0
        fi
        
        case $choice in
            1) clone_repository ;;
            2) init_repository ;;
            3) git_status ;;
            4) git_add ;;
            5) git_unstage ;;
            6) git_commit ;;
            7) git_push ;;
            8) git_pull ;;
            9) branch_operations ;;
            10) git_log ;;
            11) repo_info ;;
            12) diff_operations ;;
            13) undo_operations ;;
            14) stash_operations ;;
            15) remote_operations ;;
            16) github_cli_operations ;;
            17) git_config_management ;;
            18) edit_gitignore ;;
            19) auth_help ;;
            20) quick_commit_push ;;
            0) 
                print_color "GREEN" "Thanks for using GitHub Interactive Menu!"
                exit 0
                ;;
            *)
                print_color "RED" "Invalid choice. Please try again."
                pause
                ;;
        esac
    done
}

# Run the script
main