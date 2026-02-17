FROM python:3.11-slim

# Install kubectl, helm, git
RUN apt-get update && apt-get install -y curl git bash && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/ && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY admin-dashboard/backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY admin-dashboard/backend/ .

# Copy banana-deploy and app repos for git tag queries and rollback scripts
COPY banana-deploy/ /repos/banana-org/banana-deploy/
COPY app1/ /repos/banana-org/app1/
COPY app2/ /repos/banana-org/app2/

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
