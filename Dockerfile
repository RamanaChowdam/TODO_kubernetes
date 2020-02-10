FROM maven:3.6.3-jdk-8 as maven-java-node
# installing node 10.12 and npm 6.4.1 in docker container
RUN mkdir -p /usr/local/content/node
WORKDIR /usr/local/content/node
ADD https://nodejs.org/dist/v10.12.0/node-v10.12.0-linux-x64.tar.gz .
RUN tar -xzf node-v10.12.0-linux-x64.tar.gz && ln -s /usr/local/content/node/node-v10.12.0-linux-x64/bin/node /usr/local/bin/node && ln -s /usr/local/content/node/node-v10.12.0-linux-x64/bin/npm /usr/local/bin/npm && chown -R root:root /usr/local/content/node && rm -fR node-v10.12.0-linux-x64.tar.gz

# image for taking maven repository to decrease the time of operation
FROM wm-maven-repo:10.3.0 as wm-maven-repo

# stage for build the code
FROM maven-java-node as webapp-artifact
RUN mkdir -p /usr/local/content/app && chown -R root:root /usr/local/content/app
ADD ./ /usr/local/content/app 
WORKDIR /usr/local/content/app
# copying the artifacts from second stage wm-maven-repo
COPY --from=wm-maven-repo /root/.m2 /root/.m2
RUN  mvn clean install -Pdeployment

# deploying the war file on tomcat/webapps
FROM tomcat:8.5.50
COPY --from=webapp-artifact /usr/local/content/app/target/*.war /usr/local/tomcat/webapps/

