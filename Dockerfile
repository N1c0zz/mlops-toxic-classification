# ==========================================
# Stage 1: Builder
# ==========================================
FROM python:3.11-slim AS builder

# Set the working directory
WORKDIR /app

# Create a virtual environment inside the container
RUN python -m venv /opt/venv

# Ensure the virtual environment is used for subsequent commands
ENV PATH="/opt/venv/bin:$PATH"

# Copy only the requirements file to leverage Docker layer caching
COPY requirements.txt .

# Upgrade pip and install dependencies without storing cache
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ==========================================
# Stage 2: Final
# ==========================================
FROM python:3.11-slim

# Security best practice: create a non-root user
RUN useradd -m -r appuser

# Set working directory
WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Set environment variables:
# 1. Use the virtual environment
# 2. Prevent Python from buffering stdout/stderr
# 3. Prevent Python from writing .pyc files
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Copy the application code and the ML models
# Assuming 'dvc pull' has been run on the host machine before building
COPY --chown=appuser:appuser ./app ./app
COPY --chown=appuser:appuser ./models ./models

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8000

# Command to run the API
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]