FROM python:3.11-slim

WORKDIR /app

# Install git for packages that need it
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Update pip and install dependencies
COPY themes/boilerplate/scripts/requirements.txt .
RUN pip install --upgrade pip --root-user-action=ignore && \
    pip install --no-cache-dir -r requirements.txt --root-user-action=ignore

# Copy the script
# COPY webpage_to_hugo.py .

# Make script executable
#RUN chmod +x webpage_to_hugo.py

# Create content directory
#RUN mkdir -p content

#ENTRYPOINT ["python", "webpage_to_hugo.py"] 
