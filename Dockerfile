FROM registry.access.redhat.com/rhel7:7.4

# Written by Cassius John-Adams for the Canadian Broadcasting Corporation (CBC)
LABEL Maintainer="Cassius John-Adams <cassius.s.adams@gmail.com>"

# Install Apache webserver, no docs, then cleanup right away
RUN microdnf --enablerepo=rhel-7-server-rpms install httpd --nodocs && \
    microdnf clean all

# Copy the index.html file (a bash script) and css style into the cgi-bin
COPY ["index.html", "style.css", "/var/www/cgi-bin/"]

# Perform some updates to the httpd.conf, set up ownerships, and push logs to stdout and stderr
RUN sed -i "s/#AddHandler cgi-script .cgi/AddHandler cgi-script .html/g" /etc/httpd/conf/httpd.conf && \
    sed -i "/ScriptAlias /c\     ScriptAlias \/ \"\/var\/www\/cgi-bin\/\" " /etc/httpd/conf/httpd.conf && \
    sed -i "s/Listen 80/Listen 8080/g" /etc/httpd/conf/httpd.conf && \
    echo "LoadModule cgid_module modules/mod_cgid.so" >> /etc/httpd/conf/httpd.conf && \
    echo "LoadModule env_module modules/mod_env.so" >> /etc/httpd/conf/httpd.conf && \ 
    echo "PassEnv HTPASSWD_PATH HTPASSWD_FILE ENDPOINT OCP_GROUPS PRETTY_NAME_GROUPS OPERATIONS" >> /etc/httpd/conf/httpd.conf && \
    chown -R apache /var/www/cgi-bin && \
    chmod +x /var/www/cgi-bin/index.html && \
    chgrp -R 0 /var/www && chmod -R g=u /var/www && \
    chgrp -R 0 /usr/local/etc && chmod -R g=u /usr/local/etc && \
    chgrp -R 0 /run/httpd  && chmod -R g=u /run/httpd && \
    chgrp -R 0 /etc/httpd/logs  && chmod -R g=u /etc/httpd/logs && \
    ln -sf /dev/stdout /var/log/httpd/access_log && \
    ln -sf /dev/stderr /var/log/httpd/error_log

WORKDIR /var/www/html/

EXPOSE 8080
USER 1001

# Start up apache and specify the configuration location
ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["-D", "FOREGROUND", "-f", "/etc/httpd/conf/httpd.conf"]

