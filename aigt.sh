#!/usr/bin/env bash

# aigt - Auto Increment Git Tag
# A bash script to automatically analyze Git repos and create semantic version tags
# Version: 1.0.0

# Note: This script is sourced by zsh config and provides the 'aigt' command
# When sourced, set -e is not used to avoid breaking the shell

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

VERSION="1.0.0"
COMMIT="bash-rewrite"
DATE="$(date +%Y-%m-%d)"

# Flags
AUTO_PATCH=false
AUTO_MINOR=false
AUTO_MAJOR=false
DRY_RUN=false
NO_PUSH=false
NO_COLOR=false
TAG_PREFIX=""
WORK_DIR=""
REQUIRE_CLEAN=false
SHOW_ALL_TAGS=false
FORCE_INIT=false
INIT_VERSION="0.1.0"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

disable_colors() {
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
}

show_error() {
    echo -e "${RED}Error: $1${RESET}" >&2
}

show_success() {
    echo -e "${GREEN}$1${RESET}"
}

show_info() {
    echo -e "${BLUE}$1${RESET}"
}

show_warning() {
    echo -e "${YELLOW}$1${RESET}"
}

# ============================================================================
# GIT OPERATIONS
# ============================================================================

is_git_repo() {
    git -C "${WORK_DIR:-.}" rev-parse --git-dir &>/dev/null
}

get_all_tags() {
    git -C "${WORK_DIR:-.}" tag -l 2>/dev/null | sort -V
}

get_current_branch() {
    git -C "${WORK_DIR:-.}" branch --show-current 2>/dev/null || echo "unknown"
}

get_remote_origin() {
    git -C "${WORK_DIR:-.}" remote get-url origin 2>/dev/null || echo ""
}

get_total_commits() {
    git -C "${WORK_DIR:-.}" rev-list --count HEAD 2>/dev/null || echo "0"
}

has_uncommitted_changes() {
    [[ -n "$(git -C "${WORK_DIR:-.}" status --porcelain 2>/dev/null)" ]]
}

get_commits_since_tag() {
    local tag="$1"
    if [[ -n "$tag" ]]; then
        git -C "${WORK_DIR:-.}" log --oneline "${tag}..HEAD" 2>/dev/null
    else
        git -C "${WORK_DIR:-.}" log --oneline 2>/dev/null
    fi
}

create_tag() {
    local tag_name="$1"
    local message="$2"
    git -C "${WORK_DIR:-.}" tag -a "$tag_name" -m "$message"
}

push_tag() {
    local tag_name="$1"
    git -C "${WORK_DIR:-.}" push origin "$tag_name"
}

tag_exists() {
    local tag_name="$1"
    git -C "${WORK_DIR:-.}" tag -l "$tag_name" | grep -q "^${tag_name}$"
}

# ============================================================================
# SEMANTIC VERSION FUNCTIONS
# ============================================================================

parse_semver() {
    local tag="$1"
    local regex='^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)$'
    
    if [[ $tag =~ $regex ]]; then
        local prefix="${BASH_REMATCH[1]}"
        local major="${BASH_REMATCH[2]}"
        local minor="${BASH_REMATCH[3]}"
        local patch="${BASH_REMATCH[4]}"
        echo "${prefix}|${major}|${minor}|${patch}"
        return 0
    fi
    return 1
}

compare_versions() {
    local v1="$1"
    local v2="$2"
    
    IFS='|' read -r _ major1 minor1 patch1 <<< "$v1"
    IFS='|' read -r _ major2 minor2 patch2 <<< "$v2"
    
    if ((major1 != major2)); then
        ((major1 > major2)) && echo "1" || echo "-1"
    elif ((minor1 != minor2)); then
        ((minor1 > minor2)) && echo "1" || echo "-1"
    elif ((patch1 != patch2)); then
        ((patch1 > patch2)) && echo "1" || echo "-1"
    else
        echo "0"
    fi
}

get_latest_semver_tag() {
    local tags
    local latest_version=""
    local latest_tag=""
    
    mapfile -t tags < <(get_all_tags)
    
    for tag in "${tags[@]}"; do
        if parsed=$(parse_semver "$tag"); then
            if [[ -z "$latest_version" ]]; then
                latest_version="$parsed"
                latest_tag="$tag"
            else
                if [[ $(compare_versions "$parsed" "$latest_version") == "1" ]]; then
                    latest_version="$parsed"
                    latest_tag="$tag"
                fi
            fi
        fi
    done
    
    echo "$latest_tag"
}

detect_tag_prefix() {
    local tags
    mapfile -t tags < <(get_all_tags)
    
    for tag in "${tags[@]}"; do
        if parsed=$(parse_semver "$tag"); then
            IFS='|' read -r prefix _ _ _ <<< "$parsed"
            echo "$prefix"
            return 0
        fi
    done
    
    echo "v"
}

increment_version() {
    local version="$1"
    local increment_type="$2"
    
    IFS='|' read -r prefix major minor patch <<< "$version"
    
    case "$increment_type" in
        patch)
            echo "${prefix}|${major}|${minor}|$((patch + 1))"
            ;;
        minor)
            echo "${prefix}|${major}|$((minor + 1))|0"
            ;;
        major)
            echo "${prefix}|$((major + 1))|0|0"
            ;;
    esac
}

format_version() {
    local version="$1"
    IFS='|' read -r prefix major minor patch <<< "$version"
    echo "${prefix}${major}.${minor}.${patch}"
}

# ============================================================================
# ANALYSIS FUNCTIONS
# ============================================================================

analyze_repository() {
    if ! is_git_repo; then
        show_error "Not a git repository"
        exit 1
    fi
    
    local latest_tag
    latest_tag=$(get_latest_semver_tag)
    
    local detected_prefix
    detected_prefix=$(detect_tag_prefix)
    
    local current_branch
    current_branch=$(get_current_branch)
    
    local remote_origin
    remote_origin=$(get_remote_origin)
    
    local total_commits
    total_commits=$(get_total_commits)
    
    local has_uncommitted=false
    if has_uncommitted_changes; then
        has_uncommitted=true
    fi
    
    local commits_since
    commits_since=$(get_commits_since_tag "$latest_tag")
    
    local commits_count
    commits_count=$(echo "$commits_since" | grep -c . || echo "0")
    
    # Store in global-like variables for reuse
    ANALYSIS_LATEST_TAG="$latest_tag"
    ANALYSIS_PREFIX="$detected_prefix"
    ANALYSIS_BRANCH="$current_branch"
    ANALYSIS_REMOTE="$remote_origin"
    ANALYSIS_TOTAL_COMMITS="$total_commits"
    ANALYSIS_UNCOMMITTED="$has_uncommitted"
    ANALYSIS_COMMITS_SINCE="$commits_since"
    ANALYSIS_COMMITS_COUNT="$commits_count"
}

display_analysis() {
    echo ""
    echo -e "${BOLD}Repository Analysis${RESET}"
    echo "==================="
    echo -e "✅ Git repository detected"
    echo -e "📂 Current branch: ${CYAN}${ANALYSIS_BRANCH}${RESET}"
    echo -e "📊 Total commits: ${CYAN}${ANALYSIS_TOTAL_COMMITS}${RESET}"
    
    if [[ -n "$ANALYSIS_REMOTE" ]]; then
        echo -e "🌐 Remote origin: ${CYAN}${ANALYSIS_REMOTE}${RESET}"
    else
        echo -e "🌐 Remote origin: ${YELLOW}(none)${RESET}"
    fi
    
    if [[ -n "$ANALYSIS_LATEST_TAG" ]]; then
        echo -e "🏷️  Latest tag: ${GREEN}${ANALYSIS_LATEST_TAG}${RESET}"
    else
        echo -e "🏷️  Latest tag: ${YELLOW}(none)${RESET}"
    fi
    
    if [[ "$ANALYSIS_UNCOMMITTED" == "true" ]]; then
        show_warning "⚠️  Working tree has uncommitted changes"
    fi
    
    echo ""
    
    if [[ "$ANALYSIS_COMMITS_COUNT" -gt 0 ]]; then
        echo -e "${BOLD}Commits since last tag (${ANALYSIS_COMMITS_COUNT})${RESET}"
        echo "==========================="
        echo "$ANALYSIS_COMMITS_SINCE" | head -20 | sed 's/^/  • /'
        if [[ "$ANALYSIS_COMMITS_COUNT" -gt 20 ]]; then
            echo "  ... and $((ANALYSIS_COMMITS_COUNT - 20)) more"
        fi
        echo ""
    fi
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

prompt_version_selection() {
    local current_version="$1"
    local prefix="$2"
    
    if [[ -z "$current_version" ]]; then
        # No current version, suggest initial
        current_version="${prefix}|0|1|0"
    else
        current_version=$(parse_semver "$current_version")
    fi
    
    local patch_version
    patch_version=$(increment_version "$current_version" "patch")
    local minor_version
    minor_version=$(increment_version "$current_version" "minor")
    local major_version
    major_version=$(increment_version "$current_version" "major")
    
    echo -e "${BOLD}Select version increment:${RESET}"
    echo ""
    echo -e "  ${GREEN}1)${RESET} Patch  → $(format_version "$patch_version")  ${CYAN}(Bug fixes, small changes)${RESET}"
    echo -e "  ${GREEN}2)${RESET} Minor  → $(format_version "$minor_version")  ${CYAN}(New features, backwards compatible)${RESET}"
    echo -e "  ${GREEN}3)${RESET} Major  → $(format_version "$major_version")  ${CYAN}(Breaking changes)${RESET}"
    echo ""
    
    local choice
    read -rp "Enter choice (1-3) or 'q' to quit: " choice
    
    case "$choice" in
        1)
            echo "patch|$patch_version"
            ;;
        2)
            echo "minor|$minor_version"
            ;;
        3)
            echo "major|$major_version"
            ;;
        q|Q)
            echo "cancelled"
            ;;
        *)
            show_error "Invalid choice"
            echo "cancelled"
            ;;
    esac
}

confirm_action() {
    local tag_name="$1"
    local will_push="$2"
    
    echo ""
    echo -e "${BOLD}Confirm action:${RESET}"
    echo -e "  • Create tag: ${GREEN}${tag_name}${RESET}"
    
    if [[ "$will_push" == "true" ]]; then
        echo -e "  • Push to remote: ${CYAN}${ANALYSIS_REMOTE}${RESET}"
    else
        echo -e "  • Create locally only"
    fi
    
    echo ""
    read -rp "Proceed? (y/N): " confirm
    
    [[ "$confirm" =~ ^[Yy]$ ]]
}

# ============================================================================
# COMMANDS
# ============================================================================

cmd_version() {
    echo "aigt version $VERSION"
    echo "Commit: $COMMIT"
    echo "Built: $DATE"
}

cmd_help() {
    cat << 'EOF'
aigt - Auto Increment Git Tag

Usage:
  aigt [flags] [command]

Commands:
  status      Show repository status
  list        List all tags
  init        Initialize first tag
  version     Show version info

Flags:
  --auto-patch       Auto increment patch version
  --auto-minor       Auto increment minor version
  --auto-major       Auto increment major version
  --dry-run          Preview changes
  --no-push          Don't push to remote
  --no-color         Disable colors
  --prefix PREFIX    Tag prefix (auto-detected or 'v')
  --work-dir DIR     Working directory
  --require-clean    Require clean working tree
  --help, -h         Show help

Examples:
  aigt                    # Interactive mode
  aigt --auto-patch       # Auto increment patch
  aigt status             # Show repository status
  aigt init               # Create initial v0.1.0 tag
  aigt init --version 1.0.0  # Create custom initial tag

EOF
}

cmd_status() {
    analyze_repository
    display_analysis
    
    if [[ "$ANALYSIS_COMMITS_COUNT" -eq 0 && -n "$ANALYSIS_LATEST_TAG" ]]; then
        show_success "✅ Repository is up to date - no commits since last tag"
    elif [[ -z "$ANALYSIS_LATEST_TAG" ]]; then
        show_info "ℹ️  No semantic version tags found - consider running 'aigt init'"
    else
        show_info "📝 Ready to create new tag with $ANALYSIS_COMMITS_COUNT new commits"
    fi
}

cmd_list() {
    if ! is_git_repo; then
        show_error "Not a git repository"
        exit 1
    fi
    
    local tags
    mapfile -t tags < <(get_all_tags)
    
    if [[ ${#tags[@]} -eq 0 ]]; then
        show_info "No tags found in repository"
        return 0
    fi
    
    show_info "All tags (${#tags[@]}):"
    printf '%s\n' "${tags[@]}" | sed 's/^/  /'
}

cmd_init() {
    if ! is_git_repo; then
        show_error "Not a git repository"
        exit 1
    fi
    
    analyze_repository
    
    if [[ "$ANALYSIS_TOTAL_COMMITS" -eq 0 ]]; then
        show_error "Repository has no commits"
        exit 1
    fi
    
    if [[ -n "$ANALYSIS_LATEST_TAG" && "$FORCE_INIT" != "true" ]]; then
        show_error "Repository already has semantic version tags (latest: ${ANALYSIS_LATEST_TAG})"
        show_info "Use --force to create initial tag anyway"
        exit 1
    fi
    
    local prefix="${TAG_PREFIX:-v}"
    local tag_name="${prefix}${INIT_VERSION}"
    
    show_info "Creating initial tag: ${tag_name}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        show_info "🔍 Dry run mode - showing what would be done:"
        show_info "  • Create initial tag: ${tag_name}"
        return 0
    fi
    
    read -rp "Create initial tag ${tag_name}? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_info "Operation cancelled"
        return 0
    fi
    
    if tag_exists "$tag_name"; then
        show_error "Tag ${tag_name} already exists"
        exit 1
    fi
    
    create_tag "$tag_name" "Initial release ${INIT_VERSION}"
    show_success "✅ Created initial tag ${tag_name}"
    
    if [[ "$NO_PUSH" != "true" && -n "$ANALYSIS_REMOTE" ]]; then
        show_info "📤 Pushing tag to origin..."
        if push_tag "$tag_name"; then
            show_success "✅ Tag pushed to origin"
        else
            show_warning "⚠️ Tag created locally but failed to push"
            show_info "You can manually push the tag with: git push origin ${tag_name}"
        fi
    elif [[ -z "$ANALYSIS_REMOTE" ]]; then
        show_info "ℹ️  No remote origin configured - tag created locally only"
    fi
}

cmd_default() {
    analyze_repository
    display_analysis
    
    # Check if clean working tree is required
    if [[ "$REQUIRE_CLEAN" == "true" && "$ANALYSIS_UNCOMMITTED" == "true" ]]; then
        show_error "Working tree has uncommitted changes (use --require-clean=false to override)"
        exit 1
    fi
    
    # Check if there are commits to tag
    if [[ "$ANALYSIS_COMMITS_COUNT" -eq 0 && -n "$ANALYSIS_LATEST_TAG" ]]; then
        show_success "✅ No commits since last tag - nothing to tag"
        return 0
    fi
    
    # Determine prefix
    local final_prefix="${TAG_PREFIX:-$ANALYSIS_PREFIX}"
    
    # Auto mode or interactive mode
    local selected_type=""
    local selected_version=""
    
    if [[ "$AUTO_PATCH" == "true" || "$AUTO_MINOR" == "true" || "$AUTO_MAJOR" == "true" ]]; then
        # Auto mode
        local increment_type
        if [[ "$AUTO_PATCH" == "true" ]]; then
            increment_type="patch"
        elif [[ "$AUTO_MINOR" == "true" ]]; then
            increment_type="minor"
        else
            increment_type="major"
        fi
        
        local current_parsed
        if [[ -n "$ANALYSIS_LATEST_TAG" ]]; then
            current_parsed=$(parse_semver "$ANALYSIS_LATEST_TAG")
        else
            current_parsed="${final_prefix}|0|0|0"
        fi
        
        selected_version=$(increment_version "$current_parsed" "$increment_type")
        selected_type="$increment_type"
        
        show_info "🤖 Auto-incrementing ${increment_type} version to $(format_version "$selected_version")"
    else
        # Interactive mode
        local selection
        selection=$(prompt_version_selection "$ANALYSIS_LATEST_TAG" "$final_prefix")
        
        if [[ "$selection" == "cancelled" ]]; then
            show_info "Operation cancelled"
            return 0
        fi
        
        IFS='|' read -r selected_type selected_version <<< "$selection"
    fi
    
    local tag_name
    tag_name=$(format_version "$selected_version")
    
    # Dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        show_info "🔍 Dry run mode - showing what would be done:"
        show_info "  • Create tag: ${tag_name}"
        if [[ "$NO_PUSH" != "true" && -n "$ANALYSIS_REMOTE" ]]; then
            show_info "  • Push tag to: ${ANALYSIS_REMOTE}"
        fi
        return 0
    fi
    
    # Confirm action (unless auto mode)
    if [[ "$AUTO_PATCH" != "true" && "$AUTO_MINOR" != "true" && "$AUTO_MAJOR" != "true" ]]; then
        local will_push="false"
        [[ "$NO_PUSH" != "true" && -n "$ANALYSIS_REMOTE" ]] && will_push="true"
        
        if ! confirm_action "$tag_name" "$will_push"; then
            show_info "Operation cancelled"
            return 0
        fi
    fi
    
    # Check if tag exists
    if tag_exists "$tag_name"; then
        show_error "Tag ${tag_name} already exists"
        exit 1
    fi
    
    # Create tag
    IFS='|' read -r _ major minor patch <<< "$selected_version"
    create_tag "$tag_name" "Release ${major}.${minor}.${patch}"
    show_success "✅ Created tag ${tag_name}"
    
    # Push tag if enabled
    if [[ "$NO_PUSH" != "true" && -n "$ANALYSIS_REMOTE" ]]; then
        show_info "📤 Pushing tag to origin..."
        if push_tag "$tag_name"; then
            show_success "✅ Tag pushed to origin"
        else
            show_warning "⚠️ Tag created locally but failed to push"
            show_info "You can manually push the tag with: git push origin ${tag_name}"
        fi
    elif [[ -z "$ANALYSIS_REMOTE" ]]; then
        show_info "ℹ️  No remote origin configured - tag created locally only"
    else
        show_info "ℹ️  Tag created locally (push with: git push origin ${tag_name})"
    fi
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_args() {
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                cmd_help
                exit 0
                ;;
            --version)
                cmd_version
                exit 0
                ;;
            --auto-patch)
                AUTO_PATCH=true
                shift
                ;;
            --auto-minor)
                AUTO_MINOR=true
                shift
                ;;
            --auto-major)
                AUTO_MAJOR=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-push)
                NO_PUSH=true
                shift
                ;;
            --no-color)
                NO_COLOR=true
                disable_colors
                shift
                ;;
            --require-clean)
                REQUIRE_CLEAN=true
                shift
                ;;
            --prefix)
                TAG_PREFIX="$2"
                shift 2
                ;;
            --work-dir)
                WORK_DIR="$2"
                shift 2
                ;;
            --all)
                SHOW_ALL_TAGS=true
                shift
                ;;
            --force)
                FORCE_INIT=true
                shift
                ;;
            --version)
                INIT_VERSION="$2"
                shift 2
                ;;
            status|list|init|version)
                command="$1"
                shift
                ;;
            *)
                show_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Validate auto increment flags
    local auto_count=0
    [[ "$AUTO_PATCH" == "true" ]] && ((auto_count++))
    [[ "$AUTO_MINOR" == "true" ]] && ((auto_count++))
    [[ "$AUTO_MAJOR" == "true" ]] && ((auto_count++))
    
    if [[ $auto_count -gt 1 ]]; then
        show_error "Only one auto increment flag can be specified"
        exit 1
    fi
    
    # Execute command
    case "$command" in
        version)
            cmd_version
            ;;
        status)
            cmd_status
            ;;
        list)
            cmd_list
            ;;
        init)
            cmd_init
            ;;
        *)
            cmd_default
            ;;
    esac
}

# ============================================================================
# MAIN
# ============================================================================

_aigt_main() {
    # Enable error handling for the command execution
    setopt LOCAL_OPTIONS ERR_EXIT 2>/dev/null || set -e
    
    # Disable colors if --no-color or not a terminal
    if [[ "$NO_COLOR" == "true" || ! -t 1 ]]; then
        disable_colors
    fi
    
    parse_args "$@"
}

# Wrapper function to be called from zsh
aigt() {
    _aigt_main "$@"
}

# If script is executed directly (not sourced), run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _aigt_main "$@"
fi
