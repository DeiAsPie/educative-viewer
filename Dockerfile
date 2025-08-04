# Use the official Python image from the Docker Hub
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Create data directory for application data
RUN mkdir -p /app/data

# Expose the port the app runs on
EXPOSE 5000

# Add the command to run the application
CMD ["python", "-c", "from __init__ import create_app; app = create_app(); app.run(host='0.0.0.0', port=5000)"]
