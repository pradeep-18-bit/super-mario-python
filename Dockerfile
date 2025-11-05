# noVNC-enabled container for the Python (Pygame) Mario game
FROM python:3.11-slim

# Install OS and X11/SDL deps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xvfb x11vnc novnc websockify fluxbox \
    libgl1 libglib2.0-0 build-essential gfortran \
    libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0 \
    ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

# Upgrade pip and patch bad requirements before install
RUN pip install --upgrade pip setuptools wheel && \
    # Auto-replace old/deprecated package versions
    if [ -f requirements.txt ]; then \
        sed -i 's/pygame==2.0.0.dev10/pygame==2.5.2/g' requirements.txt && \
        sed -i 's/scipy==1.4.1/scipy==1.11.4/g' requirements.txt && \
        pip install --no-cache-dir -r requirements.txt; \
    else \
        pip install --no-cache-dir pygame==2.5.2 scipy==1.11.4; \
    fi

EXPOSE 6080

ENV VNC_PASSWORD="ChangeMe!"
ENV DISPLAY=":0"

CMD bash -lc '\
  Xvfb :0 -screen 0 1024x768x24 & \
  sleep 2 && \
  fluxbox & \
  x11vnc -display :0 -rfbport 5900 -forever -shared -passwd "$VNC_PASSWORD" -xkb -bg && \
  websockify --web=/usr/share/novnc/ 6080 localhost:5900 & \
  DISPLAY=:0 python main.py \
'
