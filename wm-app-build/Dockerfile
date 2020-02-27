# Taking the maven v3.6 base image with openjkd-8 form docker registry  
FROM maven:3.6.3-jdk-8 as maven-java-node
ENV MAVEN_CONFIG=~/.m2
# installing node 10.12 and npm 6.4.1 in docker container
RUN mkdir -p /usr/local/content/node
WORKDIR /usr/local/content/node
ADD https://nodejs.org/dist/v10.12.0/node-v10.12.0-linux-x64.tar.gz .
RUN tar -xzf node-v10.12.0-linux-x64.tar.gz \ 
    && ln -s /usr/local/content/node/node-v10.12.0-linux-x64/bin/node /usr/local/bin/node \
    && ln -s /usr/local/content/node/node-v10.12.0-linux-x64/bin/npm /usr/local/bin/npm \
    && chown -R root:root /usr/local/content/node \
    && rm -fR node-v10.12.0-linux-x64.tar.gz

# stage for build the code
FROM maven-java-node
#RUN mkdir -p /usr/local/content/app && chown -R root:root /usr/local/content/app
#ADD ./ /usr/local/content/app 
WORKDIR /usr/local/content/app
# profile arg is build time variable calling from docker-compose file
CMD mvn clean install -P{profile} && mkdir -p dist && cp -fr target/*.war dist/
