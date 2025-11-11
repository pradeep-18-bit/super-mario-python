# noVNC-enabled container for Python (Pygame) Mario game
FROM python:3.11-slim

# -----------------------------------------------------
# 🧩 1. Install system dependencies
# -----------------------------------------------------
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xvfb x11vnc xauth novnc websockify fluxbox \
    libgl1 libglib2.0-0 build-essential gfortran \
    libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0 \
    ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------
# 🧩 2. Copy game files
# -----------------------------------------------------
WORKDIR /app
COPY . /app

# -----------------------------------------------------
# 🧩 3. Upgrade pip and install Python dependencies
# -----------------------------------------------------
RUN pip install --upgrade pip setuptools wheel && \
    if [ -f requirements.txt ]; then \
        sed -i 's/pygame==2.0.0.dev10/pygame==2.5.2/g' requirements.txt && \
        sed -i 's/scipy==1.4.1/scipy==1.11.4/g' requirements.txt && \
        pip install --no-cache-dir -r requirements.txt; \
    else \
        pip install --no-cache-dir pygame==2.5.2 scipy==1.11.4; \
    fi

# -----------------------------------------------------
# 🧩 4. noVNC path fix (ensure websockify web dir exists)
# -----------------------------------------------------
RUN ln -s /usr/share/novnc /noVNC || true

# -----------------------------------------------------
# 🧩 5. Environment configuration
# -----------------------------------------------------
ENV DISPLAY=:0
ENV VNC_PASSWORD="ChangeMe!"
ENV SDL_AUDIODRIVER=dummy
ENV SDL_VIDEODRIVER=x11
ENV SDL_NOMOUSE=1
ENV SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR=0

# -----------------------------------------------------
# 🧩 6. Expose noVNC web port
# -----------------------------------------------------
EXPOSE 6080

# -----------------------------------------------------
# 🧩 7. Health check (container considered healthy if websockify is up)
# -----------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s CMD curl -f http://localhost:6080 || exit 1

# -----------------------------------------------------
# 🧩 8. Launch everything in the right order
# -----------------------------------------------------
CMD bash -lc '\
  echo "🎮 Starting Super Mario Pygame with noVNC..." && \
  Xvfb :0 -screen 0 1024x768x24 & \
  sleep 5 && \
  fluxbox & \
  sleep 5 && \
  x11vnc -display :0 -rfbport 5900 -forever -shared -passwd "$VNC_PASSWORD" -xkb -bg && \
  websockify --web=/noVNC 6080 localhost:5900 & \
  sleep 5 && \
  echo "✅ Virtual display ready! Launching game..." && \
  while true; do \
    DISPLAY=:0 SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=x11 python main.py || true; \
    echo "⚠️ Game exited — restarting in 5s..."; \
    sleep 5; \
  done \
'
