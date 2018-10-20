FROM openjdk:8-jre-alpine
VOLUME /tmp
ENV SPRING_PROFILES_ACTIVE docker

ADD https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-alpine-linux-amd64-v0.6.1.tar.gz dockerize.tar.gz
RUN tar xzf dockerize.tar.gz
RUN chmod +x dockerize
ADD target/ARTIFACT /app.jar
RUN touch /app.jar
EXPOSE PORT
ENTRYPOINT ["./dockerize","-wait=tcp://discovery-server:8761","-timeout=60s","--","java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
#CONFIG_SERVER ["java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
#DISCOVERY_SERVER ["./dockerize","-wait=tcp://config-server:8888","-timeout=60s","--","java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]