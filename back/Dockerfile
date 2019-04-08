FROM tomcat:8

EXPOSE 8080/tcp
EXPOSE 8009/tcp

RUN mkdir -p /logs

COPY ./gestion.war /usr/local/tomcat/webapps/
COPY ./tomcat-users.xml /usr/local/tomcat/conf/
COPY ./web.xml /usr/local/tomcat/conf/
COPY ./context.xml /usr/local/tomcat/conf/
COPY ./server.xml /usr/local/tomcat/conf/
COPY ./manager-context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml
COPY ./host-manager-context.xml /usr/local/tomcat/webapps/host-manager/META-INF/context.xml
