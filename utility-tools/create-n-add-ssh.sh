#!/bin/bash

# ---------------------------
# Import utils
# ---------------------------
source ./lib-logger.sh
source utils.sh


# ---------------------------
# Helper functions
# ---------------------------


# Email validation regex
validate_email() {
    local email="$1"
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if [[ $email =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

generate_key() {
    ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519 -q
}

# ========================================
#   GitHub SSH Key Generator main script
# ========================================

# Step 1: Ask for email
while true; do
    read -r -p "Enter your GitHub email address: " EMAIL
    EMAIL=$(echo "$EMAIL" | xargs)  # trim whitespace

    if [[ -z "$EMAIL" ]]; then
        log_warn "Email cannot be empty."
        continue
    fi

    if validate_email "$EMAIL"; then
        log_info "Valid email: $EMAIL"
        break
    else
        log_warn "Invalid email format. Please try again."
        log_info "   Example: user@example.com"
    fi
done

# Step 2: Get confirmation before proceeding
while true; do
    echo -e "\n"
    read -r -p $"Do you want to generate an SSH key with $EMAIL? (Y/N): " CONFIRM
    case "$CONFIRM" in
        [Y]* )
            log_info "Proceeding with SSH key generation..."
            break
            ;;
        [N]* )
            log_warn "Operation cancelled by user."
            exit 0
            ;;
        * )
            echo "Please answer Y or N."
            ;;
    esac
done

# Step 3: Generate ed25519 key
echo -e "\n"
log_info "Generating a secure ed25519 SSH key..."
generate_key

# If key already exists, ssh-keygen will ask to overwrite — we handle it gracefully
if [ $? -ne 0 ]; then
    log_warn "Key already exists or generation was cancelled."
    read -p -r "Do you want to overwrite the existing key? (Y/N): " OVERWRITE
    if [[ $OVERWRITE =~ ^[Y]$ ]]; then
        generate_key
    elif [[ $OVERWRITE =~ ^[N]$ ]]; then
        log_warn "Aborted. Existing key was not overwritten."
        exit 0
    else
        log_warn "Please answer Y or N"
    fi
fi


# Step 4: Start ssh-agent and add key
echo -e "\n"
log_info "Starting ssh-agent and adding your key..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_ed25519


# Step 5: Copy public key to clipboard
echo -e "\n"
log_info "Copying public key to clipboard..."

if command -v pbcopy >/dev/null 2>&1; then
    # macOS
    pbcopy < ~/.ssh/id_ed25519.pub
elif command -v xclip >/dev/null 2>&1; then
    # Linux with xclip
    xclip -selection clipboard < ~/.ssh/id_ed25519.pub
elif command -v clip >/dev/null 2>&1; then
    # Git Bash / WSL
    clip < ~/.ssh/id_ed25519.pub
else
    log_warn "No clipboard tool found. Copy manually:"
    echo -e "\n"
    cat ~/.ssh/id_ed25519.pub
    echo -e "\n"
    log_info "Please manually copy the above key."
fi

# Final instructions
echo -e "\n"
log_success "SUCCESS! SSH key generated and copied to clipboard."
echo -e "\nNext steps:"
echo "   1. Go to: https://github.com/settings/keys"
echo "   2. Click 'New SSH key'"
echo "   3. Paste the key (it's already in your clipboard)"
echo "   4. Give it a title (e.g., 'my_personal_workstation')"
echo -e "\nTest your connection:"
echo "   ssh -T git@github.com"
echo -e "\n"
log_success "You're all set! Happy coding!"
echo -e "\n"
