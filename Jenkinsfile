pipeline {
    agent any

    environment {
        REGISTRY_USER  = "jorgito170"
        IMAGE_NAME     = "retail-store-u202316057"
        TAG            = "v1.0.${BUILD_NUMBER}"
        SONAR_PROJECT  = "retail-store-u202316057"
        // JDK 26 instalado en la imagen jenkins-ci-cd:2026.final
        JAVA_HOME      = "/usr/lib/jvm/temurin-26-amd64"
        PATH           = "/usr/lib/jvm/temurin-26-amd64/bin:${env.PATH}"
    }

    stages {

        stage('1. Checkout') {
            steps {
                checkout scm
                echo "Repositorio clonado correctamente"
            }
        }

        stage('2. Build & Test') {
            steps {
                sh 'chmod +x mvnw && ./mvnw clean verify -B'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('3. Análisis SonarQube') {
            steps {
                withSonarQubeEnv('MiSonarServer') {
                    sh """
                        chmod +x mvnw
                        ./mvnw sonar:sonar \
                          -Dsonar.projectKey=${SONAR_PROJECT} \
                          -Dsonar.projectName="${IMAGE_NAME}" \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                          -Dcheckstyle.skip=true \
                          -DskipTests \
                          -B
                    """
                }
            }
        }

        stage('4. Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('5. Construir y Publicar Imagen Docker') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DOCKER_HUB_CREDENTIALS',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        echo "Iniciando sesión en Docker Hub..."
                        sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"

                        echo "Construyendo y publicando imagen AMD64: ${REGISTRY_USER}/${IMAGE_NAME}:${TAG}"
                        sh """
                            docker buildx build \
                              --platform linux/amd64 \
                              -t ${REGISTRY_USER}/${IMAGE_NAME}:${TAG} \
                              -t ${REGISTRY_USER}/${IMAGE_NAME}:latest \
                              --push .
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completado. Imagen disponible en: ${REGISTRY_USER}/${IMAGE_NAME}:${TAG}"
        }
        failure {
            echo "El pipeline ha fallado. Revisar los logs de cada stage."
        }
        cleanup {
            sh "docker logout || true"
        }
    }
}
