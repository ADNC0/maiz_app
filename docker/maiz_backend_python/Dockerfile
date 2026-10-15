FROM python:3.10-slim

WORKDIR /app

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia el requirements.txt
COPY requirements.txt .

# Fuerza la versión correcta de TensorFlow
RUN pip install --upgrade pip
RUN pip install --no-cache-dir tensorflow==2.18.0
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install psycopg2-binary

# Copia el resto del proyecto
COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
