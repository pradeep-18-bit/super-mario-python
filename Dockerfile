# noVNC-enabled container for the Python (Pygame) Mario game
FROM python:3.11-slim

# System deps for virtual display + VNC + noVNC + SDL
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xvfb x11vnc novnc websockify fluxbox \
    libgl1 libglib2.0-0 \
    libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0 \
    ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

# Install Python deps: use requirements.txt if present, else install pygame
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; else pip install --no-cache-dir pygame; fi

# noVNC web will be on 6080
EXPOSE 6080

# Set defaults (change at runtime via -e)
ENV VNC_PASSWORD="ChangeMe!"
ENV DISPLAY=":0"

# Start X server, WM, VNC, noVNC, then the game
CMD bash -lc '\
  Xvfb :0 -screen 0 1024x768x24 & \
  sleep 1 && \
  fluxbox & \
  x11vnc -display :0 -rfbport 5900 -forever -shared -passwd "$VNC_PASSWORD" -xkb -bg && \
  websockify --web=/usr/share/novnc/ 6080 localhost:5900 & \
  DISPLAY=:0 python main.py \
'
