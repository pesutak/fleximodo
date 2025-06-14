#!/bin/bash
# build_content.sh
#
# This script creates a virtual environment, installs requirements,
# and performs three main tasks:
# 1. Translates missing content files from English to other languages using FlowHunt API
# 2. Generates related content YAML files for the Hugo site
# 3. Preprocesses images for optimal web delivery


# Run the container
#echo "Running webpage-to-hugo container..."
#docker run --rm --network host webpage-to-hugo "${ARGS[@]}" 

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

# Build the Docker image
echo "Building python Docker image..."
docker build --network host -t python .

# Function to run Python scripts via Docker
run_python() {
    local script_path="$1"
    shift  # Remove the first argument (script_path) so $@ contains only the remaining arguments
    
    echo "Running Python script via Docker: $(basename "$script_path")"
    docker run --rm --network host \
        -v "${SCRIPT_DIR}:/app/scripts" \
        -v "${HUGO_ROOT}:/app/hugo" \
        -v "${THEME_DIR}:/app/theme" \
        --env-file "${SCRIPT_DIR}/.env" \
        -w /app/scripts \
        python python "$(basename "$script_path")" "$@"
}

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
            run_python sync_translations.py
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
            run_python offload_replicate_images.py
            echo -e "${GREEN}Offloading images completed!${NC}"
            ;;
        translate)
            echo -e "${BLUE}=== Step 3: Translating Missing Content with FlowHunt API ===${NC}"
            echo -e "${YELLOW}Running FlowHunt translation script...${NC}"
            run_python translate_with_flowhunt.py --path "${HUGO_ROOT}/content"
            echo -e "${GREEN}Translation of missing content completed!${NC}"
            ;;
        sync_content_attributes)
            echo -e "${BLUE}=== Step 3.5: Validating Content Files after translation ===${NC}"
            run_python sync_content_attributes.py
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
            run_python translation-urls.py --hugo-root "${HUGO_ROOT}"
            echo -e "${GREEN}Translation URLs mapping completed!${NC}"
            ;;
        generate_related_content)
            echo -e "${BLUE}=== Step 4: Generating Related Content ===${NC}"
            run_python generate_related_content.py --path "${HUGO_ROOT}/content" --hugo-root "${HUGO_ROOT}"
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

