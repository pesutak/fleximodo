#!/bin/bash
# build_content.sh
#
# This script creates a virtual environment, installs requirements,
# and performs three main tasks:
# 1. Translates missing content files from English to other languages using FlowHunt API
# 2. Generates related content YAML files for the Hugo site
# 3. Preprocesses images for optimal web delivery

set -e  # Exit immediately if a command exits with a non-zero status

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THEME_DIR="$(dirname "$SCRIPT_DIR")"
HUGO_ROOT="$(dirname "$(dirname "$THEME_DIR")")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#print directories
echo -e "${BLUE}=== Directories ===${NC}"
echo -e "${BLUE}Script directory: ${SCRIPT_DIR}${NC}"
echo -e "${BLUE}Theme directory: ${THEME_DIR}${NC}"
echo -e "${BLUE}Hugo root: ${HUGO_ROOT}${NC}"

echo -e "${BLUE}=== Building Content for Hugo Site ===${NC}"
echo -e "${BLUE}Hugo root: ${HUGO_ROOT}${NC}"

# Create a virtual environment if it doesn't exist
VENV_DIR="${SCRIPT_DIR}/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
else
    echo -e "${YELLOW}Using existing virtual environment...${NC}"
fi

# Activate the virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source "${VENV_DIR}/bin/activate"

# Install or upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip

# Install requirements
echo -e "${YELLOW}Installing requirements...${NC}"
pip install -r "${SCRIPT_DIR}/requirements.txt"

# Check for FlowHunt API key
if [ -z "$FLOWHUNT_API_KEY" ]; then
    echo -e "${YELLOW}Checking for FlowHunt API key...${NC}"
    if [ ! -f "${SCRIPT_DIR}/.env" ]; then
        echo -e "${YELLOW}No .env file found. Please enter your FlowHunt API key:${NC}"
        read -p "FlowHunt API Key: " flow_api_key
        echo "FLOWHUNT_API_KEY=${flow_api_key}" >> "${SCRIPT_DIR}/.env"
    elif ! grep -q "FLOWHUNT_API_KEY" "${SCRIPT_DIR}/.env"; then
        echo -e "${YELLOW}FlowHunt API key not found in .env file. Please enter your FlowHunt API key:${NC}"
        read -p "FlowHunt API Key: " flow_api_key
        echo "FLOWHUNT_API_KEY=${flow_api_key}" >> "${SCRIPT_DIR}/.env"
    fi
fi

# Parse arguments for step selection
STEPS_TO_RUN=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --step|--steps)
            IFS=',' read -ra STEPS_TO_RUN <<< "$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

run_step() {
    step_name="$1"
    case "$step_name" in
        sync_translations)
            echo -e "${BLUE}=== Step 0: Syncing Translation Keys ===${NC}"
            python "${SCRIPT_DIR}/sync_translations.py"
            echo -e "${GREEN}Translation key sync completed!${NC}"
            ;;
        validate_content)
            echo -e "${BLUE}=== Step 1: Validating Content Files ===${NC}"
            bash "${SCRIPT_DIR}/validate_content.sh" --path "${HUGO_ROOT}/content"
            if [ $? -ne 0 ]; then
                echo -e "${YELLOW}Content file validation failed. Stopping further processing.${NC}"
                exit 1
            fi
            echo -e "${GREEN}Content file validation completed!${NC}"
            ;;
        offload_images)
            echo -e "${BLUE}=== Step 2: Offload Images from Replicate ===${NC}"
            python "${SCRIPT_DIR}/offload_replicate_images.py"
            echo -e "${GREEN}Offloading images completed!${NC}"
            ;;
        translate)
            echo -e "${BLUE}=== Step 3: Translating Missing Content with FlowHunt API ===${NC}"
            echo -e "${YELLOW}Running FlowHunt translation script...${NC}"
            python "${SCRIPT_DIR}/translate_with_flowhunt.py" --path "${HUGO_ROOT}/content"
            echo -e "${GREEN}Translation of missing content completed!${NC}"
            ;;
        sync_content_attributes)
            echo -e "${BLUE}=== Step 3.5: Validating Content Files after translation ===${NC}"
            python "${SCRIPT_DIR}/sync_content_attributes.py"
            echo -e "${GREEN}Content attributes sync completed!${NC}"
            ;;
        validate_content_post)
            echo -e "${BLUE}=== Step 3.6: Validating Content Files after translation ===${NC}"
            bash "${SCRIPT_DIR}/validate_content.sh" --path "${HUGO_ROOT}/content"
            if [ $? -ne 0 ]; then
                echo -e "${YELLOW}Content file validation failed. Stopping further processing.${NC}"
                exit 1
            fi
            echo -e "${GREEN}Content file validation completed!${NC}"
            ;;
        generate_translation_urls)
            echo -e "${BLUE}=== Step 3.7: Generating Translation URLs Mapping ===${NC}"
            python "${SCRIPT_DIR}/translation-urls.py" --hugo-root "${HUGO_ROOT}"
            echo -e "${GREEN}Translation URLs mapping completed!${NC}"
            ;;
        generate_related_content)
            echo -e "${BLUE}=== Step 4: Generating Related Content ===${NC}"
            python "${SCRIPT_DIR}/generate_related_content.py" --path "${HUGO_ROOT}/content" --hugo-root "${HUGO_ROOT}" --exclude-sections "author"
            echo -e "${GREEN}Related content generation completed!${NC}"
            ;;
        preprocess_images)
            echo -e "${BLUE}=== Step 5: Preprocessing Images ===${NC}"
            echo -e "${YELLOW}Running image preprocessing script...${NC}"
            source "${SCRIPT_DIR}/preprocess-images.sh"
            process_all_images
            echo -e "${GREEN}Image preprocessing completed!${NC}"
            ;;
        *)
            echo -e "${YELLOW}Unknown step: $step_name${NC}"
            ;;
    esac
}

# If no steps specified, run all steps
if [ ${#STEPS_TO_RUN[@]} -eq 0 ]; then
    STEPS_TO_RUN=(sync_translations validate_content offload_images translate sync_content_attributes validate_content_post generate_translation_urls generate_related_content preprocess_images)
fi

for step in "${STEPS_TO_RUN[@]}"; do
    run_step "$step"
done

# Deactivate the virtual environment
deactivate

echo -e "${GREEN}Done! All content processing completed successfully.${NC}"
