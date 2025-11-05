pipeline {
  agent any

  environment {
    APP_NAME     = "mario-novnc"
    IMAGE_TAG    = "latest"
    VNC_PASSWORD = credentials('vnc-password') // Create a Jenkins Secret Text with this ID
  }

  options {
    timestamps()
  }

  stages {
    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }

    stage('Checkout Repository') {
      steps {
        // Replace with your own repo URL if different
        git branch: 'main', url: 'https://github.com/your-username/super-mario-python.git'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Smoke Test (Headless)') {
      steps {
        sh """
          docker run --rm ${APP_NAME}:${IMAGE_TAG} \
            bash -lc "DISPLAY=:99 xvfb-run -s '-screen 0 640x480x24' python - <<'PY'
import os
os.environ['SDL_VIDEODRIVER']='dummy'
import pygame
pygame.init()
pygame.display.set_mode((320,240))
pygame.quit()
print('OK')
PY"
        """
      }
    }

    stage('Deploy (Run Game Container)') {
      steps {
        sh """
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} -p 6080:6080 \\
            -e VNC_PASSWORD='${VNC_PASSWORD}' \\
            ${APP_NAME}:${IMAGE_TAG}
        """
      }
    }
  }

  post {
    success {
      echo "🎮 Game deployed! Access it at: http://<EC2-IP>:6080"
    }
    failure {
      echo "❌ Build failed. Check Jenkins console logs."
    }
  }
}
