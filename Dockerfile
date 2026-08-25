# Use an official Python runtime as a parent image.
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory
WORKDIR /app

# Copy the dependencies file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Run the FastAPI app with Uvicorn
CMD ["uvicorn", "orchestrator.src.main:app", "--host", "0.0.0.0", "--port", "8080"]