def project = 'petclinic-microservice'
def appName = 'config-server'
def appPort = 8888
def artifactName = 'config-server-2.0.6.BUILD-SNAPSHOT.jar'
def testingdns = ''
def  imageTag = "${appName}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
//def tempBucket = "${project}-${appName}-${env.BUILD_NUMBER}"


pipeline {
    agent {
        kubernetes {
            serviceAccount 'cd-jenkins'
            label 'mypod'
            defaultContainer 'jnlp'
            yaml """
kind: Pod
metadata:
  name: slave
spec:
  containers:
  - name: maven
    image: maven:alpine
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
    volumeMounts:
      - name: maven-repo
        mountPath: /root/.m2/repository
        
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    imagePullPolicy: IfNotPresent
    command:  
    - cat
    tty: true

  - name: zap
    image: owasp/zap2docker-stable:2.7.0
    imagePullPolicy: IfNotPresent
    command:  
    - /bin/cat
    tty: true
    securityContext:
      runAsUser: 0
    
  - name: python3
    image: python:3.7-stretch
    imagePullPolicy: IfNotPresent
    command:  
    - cat
    tty: true

  - name: claircli
    image: python:2.7-alpine
    imagePullPolicy: IfNotPresent
    command:  
    - cat
    tty: true
    
  - name: defectdojocli
    image: python:2.7
    imagePullPolicy: IfNotPresent
    command:  
    - cat
    tty: true
    
  - name: ddtrackcli
    image: python:2.7
    imagePullPolicy: IfNotPresent
    command:  
    - cat
    tty: true    
    
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug-7a7d5449168da6fb0e45a8cfc625ed7a7e7bd9f3
    imagePullPolicy: IfNotPresent
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /root
        
  volumes:
  - name: jenkins-docker-cfg
    projected:
      sources:
      - secret:
          name: regcred
          items:
            - key: .dockerconfigjson
              path: .docker/config.json
  - name: maven-repo
    emptyDir: {}
"""
        }
    }

    stages {

        /*stage('Checkout') {
            checkout scm
            //git branch: 'mergeAll', url: 'https://github.com/guigeek123/spring-petclinic-jenkins-kubernetes.git'
        }*/

        stage('Prepare') {
            steps {
                // Using a Python Based image to download pipeline-tools
                container('python3') {
                    sh 'curl -L https://github.com/guigeek123/spring-petclinic-jenkins-kubernetes/releases/download/v0.5/pipeline-tools-v0.5.tar.gz --output pipeline-tools.tar.gz'
                    sh 'tar xvzf pipeline-tools.tar.gz'
                    sh 'chown 770 -R pipeline-tools'
                }

                // Customize dockerfile for current microservice
                container('python3') {
                    sh("sed -i.bak 's#ARTIFACT#${artifactName}#' ./Dockerfile")
                    sh("sed -i.bak 's#PORT#${appPort}#' ./Dockerfile")

                    script {
                        if ("${appName}" == 'config-server') {
                            sh("sed -i.bak 's/ENTRYPOINT/#/g' ./Dockerfile")
                            sh("sed -i.bak 's/#CONFIG_SERVER/ENTRYPOINT/g' ./Dockerfile")
                        }

                        if ("${appName}" == 'discovery-server') {
                            sh("sed -i.bak 's/ENTRYPOINT/#/g' ./Dockerfile")
                            sh("sed -i.bak 's/#DISCOVERY_SERVER/ENTRYPOINT/g' ./Dockerfile")
                        }
                    }

                    //sh("cat ./Dockerfile")

                }

                container('kubectl') {

                    // Customize deployments files for current microservice

                    // Create dedicated deployment yaml for testing
                    sh 'cp ./k8s/app/* k8s/test/'

                    //Get node internal ip to access nexus docker registry exposed as nodePort (nexus-direct-nodeport.yaml) and replace it yaml file
                    sh 'sed -i.bak \"s#NODEIP#$(kubectl get nodes -o jsonpath="{.items[1].status.addresses[?(@.type==\\"InternalIP\\")].address}")#\" ./k8s/app/*.yaml'
                    sh 'sed -i.bak \"s#NODEIP#$(kubectl get nodes -o jsonpath="{.items[1].status.addresses[?(@.type==\\"InternalIP\\")].address}")#\" ./k8s/test/*.yaml'
                    //Write the image to be deployed in the yaml deployment file
                    sh("sed -i.bak 's#CONTAINERNAME#${imageTag}#' ./k8s/app/*.yaml")
                    sh("sed -i.bak 's#CONTAINERNAME#${imageTag}#' ./k8s/test/*.yaml")
                    //Personalizes the deployment file with application name
                    sh("sed -i.bak 's#appName#${appName}#' ./k8s/app/*.yaml")
                    sh("sed -i.bak 's#appName#${appName}-${env.BRANCH_NAME}#' ./k8s/test/*.yaml")
                    sh("sed -i.bak 's#projectName#${project}#' ./k8s/app/*.yaml")
                    sh("sed -i.bak 's#projectName#${project}#' ./k8s/test/*.yaml")
                    sh("sed -i.bak 's#appPort#${appPort}#' ./k8s/app/*.yaml")
                    sh("sed -i.bak 's#appPort#${appPort}#' ./k8s/test/*.yaml")

                    //sh("cat k8s/app/deployment.yaml")
                    //sh("cat k8s/app/service.yaml")
                    //sh("cat k8s/test/deployment.yaml")
                    //sh("cat k8s/test/service.yaml")
                    //sh("cat k8s/test/internamespace-service.yaml")

                    //Manage Nexus secret
                    // SECURITY WARNING : password displayed in jenkins Logs
                    sh 'sed -i.bak \"s#NEXUSLOGIN#$(kubectl get secret nexus-admin-pass -o jsonpath="{.data.username}" | base64 --decode)#\" pipeline-tools/maven/maven-custom-settings'
                    sh 'sed -i.bak \"s#NEXUSPASS#$(kubectl get secret nexus-admin-pass -o jsonpath="{.data.password}" | base64 --decode)#\" pipeline-tools/maven/maven-custom-settings'
                }
            }
        }


        stage('Sonar and Dependency-Check') {

            when {
                anyOf {
                    branch '*-acceptance';
                    branch '*-production'
                }
            }

            steps {
                container('maven') {
                    // ddcheck=true will activate dependency-check scan (configured in POM.xml via a profile)
                    sh 'mvn -s pipeline-tools/maven/maven-custom-settings clean verify -Dddcheck=true sonar:sonar'
                    sh 'mkdir reports && mkdir reports/dependency && cp target/dependency-check-report.xml reports/dependency/'
                    // WARNING SECURITY : Change permission to make other container able to move reports in that directory (to be patched)
                    sh 'chmod 777 reports'
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'target/', reportFiles: 'dependency-check-report.html', reportName: 'Dependency-Check Report', reportTitles: ''])
                }


                script {
                    try {
                        withCredentials([string(credentialsId: 'ddtrack_apikey', variable: 'ddtrack_apikey')]) {
                            container('ddtrackcli') {
                                sh('pip install requests')
                                sh("pipeline-tools/dependency-track/scripts/ddtrack-cli.py -k ${env.ddtrack_apikey} -x target/dependency-check-report.xml -p ${project} -u http://ddtrack-service")
                            }
                        }
                    } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException e) {
                        println "Export to Dependency Track not activated : please set up the api key in ddtrack_apikey secret"
                    }
                }

            }
        }


        stage('Build with Maven') {
            steps {
                container('maven') {
                    sh 'mvn -s pipeline-tools/maven/maven-custom-settings clean deploy -DskipTests'
                }
            }
        }


        stage('Build Docker image with Kaniko') {

            steps {
                // Useless step, we get the jar from the "target" directory, see Dockerfile
                /*container('maven') {
                    sh 'mkdir targetDocker'
                    sh 'cd targetDocker && mvn -s ../pipeline-tools/maven/maven-custom-settings org.apache.maven.plugins:maven-dependency-plugin::get -DgroupId=org.springframework.samples -DartifactId=spring-petclinic -Dversion=2.0.0.BUILD-SNAPSHOT -Dpackaging=jar -Ddest=app.jar'
                }*/

                container(name: 'kaniko', shell: '/busybox/sh') {
                    withEnv(['PATH+EXTRA=/busybox']) {
                        sh """#!/busybox/sh
                            /kaniko/executor --dockerfile=Dockerfile -c `pwd` --destination=nexus-direct:8083/${imageTag} --insecure
                        """
                    }
                }
            }


        }

        stage('Scan image with CLAIR') {

            when {
                anyOf {
                    branch '*-acceptance';
                    branch '*-production'
                }
            }

            steps {
                // Execute scan and analyse results
                script {
                    try {
                        container('claircli') {
                            // Prerequisites installation on python image
                            // Could be optimized by providing a custom docker image, built and pushed to github before...
                            sh 'pip install --no-cache-dir -r pipeline-tools/clair/scripts/requirements.txt'

                            // Executing customized Yair script
                            // --no-namespace cause docker image is not pushed withi a "Library" folder in Nexus
                            sh "cd pipeline-tools/clair/scripts/ && chmod +x yair-custom.py && ./yair-custom.py ${imageTag} --no-namespace"


                        }
                    } catch (all) {
                        // TODO : Show an information on jenkins to say that the gate is not OK but not block the build
                    } finally {
                        // Move JSON report to be uploaded later in defectdojo
                        sh "mkdir -p reports"
                        sh "mkdir reports/clair && cp pipeline-tools/clair/scripts/clair-results.json reports/clair/"
                    }
                }

            }
        }

        stage('DAST with ZAP') {

            when {
                anyOf {
                    branch '*-acceptance';
                    branch '*-production'
                }
            }

            steps {
                container('kubectl') {
                    // Deploy to testing namespace, with the docker image created before
                    sh 'kubectl apply -f ./k8s/test/deployment.yaml --namespace=testing'
                    sh 'kubectl apply -f ./k8s/test/service.yaml --namespace=testing'

                    // Deploy an "internamespace service" to make the testing app accessible from the default namespace where zap is running
                    sh 'kubectl apply -f ./k8s/test/internamespace-service.yaml'
                }

                // Execute scan

                container('zap') {
                    sh("pip install python-owasp-zap-v2.4")
                    sh("zap-cli start -o '-config api.disablekey=true'")
                    //Give a chance to the app to start
                    sh 'sleep 30'
                    //TODO : configure scanners
                    script {
                        try {
                            sh("zap-cli quick-scan -o '-config api.disablekey=true' -l Low --spider -r http://${appName}-${env.BRANCH_NAME}-defaultns:${appPort}/")
                        } catch (all) {
                            //scripts gives error if any findings. Errors are not managed here.
                        }
                    }

                    sh("zap-cli report -f xml -o zap-results.xml")
                    sh("zap-cli report -f html -o pipeline-tools/zap/scripts/results.html")
                    //Getting JSON results using custom script, not available in zap-cli...
                    sh("pipeline-tools/zap/scripts/zap-get-json-results.py")
                    sh("zap-cli shutdown")
                    //Note : Carefull to privileges
                    //Note : XML version required for DefectDojo, Json version required for Security Gate
                    sh "mkdir -p reports"
                    sh "mkdir reports/zap && cp zap-results.xml reports/zap/"

                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'pipeline-tools/zap/scripts/', reportFiles: 'results.html', reportName: 'ZAP full report', reportTitles: ''])
                }

                // Destroy app from testing namespace
                container('kubectl') {
                    sh "kubectl delete service ${appName}-${env.BRANCH_NAME}-defaultns"
                    sh "kubectl delete deployment ${appName}-${env.BRANCH_NAME} --namespace=testing"
                    sh "kubectl delete service ${appName}-${env.BRANCH_NAME} --namespace=testing"
                }
            }
        }


        stage('Upload Reports to DefectDojo') {
            when {
                anyOf {
                    branch '*-acceptance';
                    branch '*-production'
                }
            }
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'defectdojo_apikey', variable: 'defectdojo_apikey')]) {
                            container('defectdojocli') {
                                sh('pip install requests')
                                sh("cd pipeline-tools/defectdojo/scripts/ && chmod +x dojo_ci_cd.py && ./dojo_ci_cd.py --host http://defectdojo:80 --api_key ${env.defectdojo_apikey} --build_id ${env.BUILD_NUMBER} --user admin --product ${appName}_${project} --dir ../../../reports/")
                            }
                        }

                    } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException e) {
                        println "Export to Defect Dojo not activated : please set up the api key in defectdojo_apikey secret"
                    }
                }
            }

        }

        stage('Deploy to Dev') {

            when {
                not {
                    anyOf {
                        branch '*-acceptance';
                        branch '*-production'
                    }
                }
            }

            steps {
                container('kubectl') {
                    // Create namespace if it doesn't exist
                    sh("kubectl get ns development || kubectl create ns development")
                    //Deploy application
                    sh("kubectl --namespace=development apply -f k8s/app/")
                }
            }
        }

        stage('Security Gate (non blocking)') {

            when { branch '*-acceptance' }

            steps{
                container('python3') {
                    sh 'pip install behave'
                    script {
                        try {
                            sh 'cp gate_config/security_gate.feature pipeline-tools/gate/features/'
                            sh 'cd pipeline-tools/gate && behave'
                        } catch(all) {
                            //non blocking gate
                            //TODO publish gate info in jenkins
                        }
                    }

                }
            }

        }


        stage('Deploy to Acceptance') {

            when { branch '*-acceptance'}

            steps {
                container('kubectl') {
                    //Deploy application
                    sh("kubectl --namespace=acceptance apply -f k8s/app/*.yaml")
                }
            }
        }

        stage('Security Gate') {

            when { branch '*-production' }

            steps{
                container('python3') {
                    sh 'pip install behave'
                    script {
                        sh 'cp gate_config/security_gate.feature pipeline-tools/gate/features/'
                        sh 'cd pipeline-tools/gate && behave'
                    }

                }
            }

        }

        stage('Deploy to Production') {

            when { branch '*-production'}

            //TODO : create a SECURITY GATE script

            steps {
                container('kubectl') {
                    //Get node internal ip to access nexus docker registry exposed as nodePort (nexus-direct-nodeport.yaml) and replace it yaml file
                    sh 'sed -i.bak \"s#NODEIP#$(kubectl get nodes -o jsonpath="{.items[1].status.addresses[?(@.type==\\"InternalIP\\")].address}")#\" ./k8s/production/*.yaml'
                    //Write the image to be deployed in the yaml deployment file
                    sh("sed -i.bak 's#CONTAINERNAME#${imageTag}#' ./k8s/production/*.yaml")
                    //Personalizes the deployment file with application name
                    sh("sed -i.bak 's#appName#${appName}#' ./k8s/production/*.yaml")
                    sh("sed -i.bak 's#appName#${appName}#' ./k8s/services/frontend.yaml")
                    //Deploy application
                    sh("kubectl --namespace=production apply -f k8s/services/frontend.yaml")
                    sh("kubectl --namespace=production apply -f k8s/production/")
                    //Display access
                    // TODO : put back LoadBalancer deployment, and add a timer to wait for IP attribution
                    //sh("echo http://`kubectl --namespace=production get service/${feSvcName} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${feSvcName}")
                }
            }
        }

    }

}
