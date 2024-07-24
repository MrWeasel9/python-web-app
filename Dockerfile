FROM python:3.6-slim-buster

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    gcc \
    libpq-dev

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Command to run the application
CMD ["python", "app.py"]
