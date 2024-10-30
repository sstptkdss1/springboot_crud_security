#
# Build stage
#

# Maven Wrapper Build
FROM ghcr.io/shclub/openjdk:17-alpine AS MAVEN_BUILD

# 빌드 디렉토리 생성 및 작업 디렉토리 설정
RUN mkdir -p /build
WORKDIR /build

# Maven 빌드를 위한 파일 복사
COPY pom.xml ./
COPY src ./src                             
COPY mvnw ./         

# Maven Wrapper 권한 추가 (권한이 없을 경우 빌드가 실패할 수 있음)
RUN chmod +x ./mvnw

# 빌드 실행
RUN ./mvnw clean package -Dmaven.test.skip=true

#
# Package stage
#
# Production 환경 설정
FROM eclipse-temurin:17.0.13_11-jre

# 빌드 결과물 복사
COPY --from=MAVEN_BUILD /build/target/*.jar /app.jar

# Spring Profile 설정
ENV SPRING_PROFILES_ACTIVE=dev

### Azure Opentelemetry ###
COPY agent/applicationinsights-agent-3.5.4.jar /applicationinsights-agent-3.5.4.jar 
COPY agent/applicationinsights.json /applicationinsights.json
ENV APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=02a052e7-48b4-408a-ad85-9dfcefed3b77;IngestionEndpoint=https://koreacentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://koreacentral.livediagnostics.monitor.azure.com/;ApplicationId=56ac42e7-29ef-47d4-b061-d0715aa7deda"
### Azure Opentelemetry ###

# Elastic APM Agent 복사 (존재하는지 확인 필요)
COPY elastic-apm-agent-1.43.0.jar /

# 타임존 설정
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# JAVA_OPTS 설정
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm"
ENV JAVA_OPTS="${JAVA_OPTS} -XX:+UseG1GC -XX:+UnlockDiagnosticVMOptions -XX:+G1SummarizeConcMark -XX:InitiatingHeapOccupancyPercent=35 -XX:G1ConcRefinementThreads=20"

### Azure Opentelemetry Agent 설정 ###
ENV JAVA_OPTS="${JAVA_OPTS} -javaagent:/applicationinsights-agent-3.5.4.jar"
### Azure Opentelemetry Agent 설정 끝 ###

# 포트 노출
EXPOSE 8080

# 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar"]



# #
# # Build stage
# #

# #### 1) Maven build
# #FROM  ghcr.io/shclub/maven:3.8.4-openjdk-17 AS MAVEN_BUILD

# #RUN mkdir -p build
# #WORKDIR /build

# #COPY pom.xml ./
# #COPY src ./src

# #COPY . ./

# #RUN mvn clean install -DskipTests

# ## 2)  Maven Wrapper Build

# FROM ghcr.io/shclub/openjdk:17-alpine AS MAVEN_BUILD

# RUN mkdir -p build
# WORKDIR /build

# COPY pom.xml ./
# COPY src ./src                             
# COPY mvnw ./         
# COPY . ./

# RUN ./mvnw clean package -Dmaven.test.skip=true

# #
# # Package stage
# #
# # production environment


# FROM eclipse-temurin:17.0.13_11-jre
# #FROM eclipse-temurin:17.0.2_8-jre-alpine
# #FROM ghcr.io/shclub/jre17-runtime:v1.0.0

# COPY --from=MAVEN_BUILD /build/target/*.jar app.jar

# ENV SPRING_PROFILES_ACTIVE dev

# ### Azure Opentelemetry ###
# COPY agent/applicationinsights-agent-3.5.4.jar applicationinsights-agent-3.5.4.jar 
# COPY agent/applicationinsights.json applicationinsights.json
# ENV APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=02a052e7-48b4-408a-ad85-9dfcefed3b77;IngestionEndpoint=https://koreacentral-0.in.applicationinsights.azure.com/;LiveEndpoint=https://koreacentral.livediagnostics.monitor.azure.com/;ApplicationId=56ac42e7-29ef-47d4-b061-d0715aa7deda"
# ### Azure Opentelemetry ###

# ENV TZ Asia/Seoul
# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# ENV SPRING_PROFILES_ACTIVE dev

# ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm"
# ENV JAVA_OPTS="${JAVA_OPTS} -XX:+UseG1GC -XX:+UnlockDiagnosticVMOptions -XX:+G1SummarizeConcMark -XX:InitiatingHeapOccupancyPercent=35 -XX:G1ConcRefinementThreads=20"

# ### Azure Opentelemerty ###
# ENV JAVA_OPTS="${JAVA_OPTS} -javaagent:applicationinsights-agent-3.5.4.jar"
# ### Azure Opentelemerty ###


# EXPOSE 8080

# #ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar  app.jar "]
# #ENTRYPOINT ["sh", "-c", "java -jar  app.jar "]
# ENTRYPOINT ["sh","-c","java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar"]
