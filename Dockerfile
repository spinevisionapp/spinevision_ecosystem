# Use an official Python runtime as a parent image.
# Using a slim image helps to keep the final image size down.
FROM python:3.10-slim

# Set environment variables to make Python run better inside Docker
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file to the working directory
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code from the host to the container
COPY . .

# Run the web server with Gunicorn.
# Using the shell form for CMD to allow environment variable expansion ($PORT).
CMD gunicorn --bind 0.0.0.0:$PORT --workers 2 --threads 8 --timeout 0 main:app