FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y curl

# creates a home directory for the user and ensures that bash is the default shell
#RUN useradd -ms /bin/bash omer

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ templates/

EXPOSE 5000
#USER omer
CMD ["python", "app.py"]