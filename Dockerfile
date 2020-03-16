FROM ubuntu:bionic

RUN apt-get -y update; \
    apt-get -y install software-properties-common dpkg-dev git; \
    add-apt-repository -y ppa:nginx/stable; \
    sed -i '/^#.* deb-src /s/^#//' /etc/apt/sources.list.d/nginx-ubuntu-stable-bionic.list; \
    apt-get -y update; \
    apt-get -y source nginx; \
    cd $(find . -maxdepth 1 -type d -name "nginx*") && \
    ls -ahl && \
    git clone https://github.com/arut/nginx-rtmp-module.git && \
    sed -i "s|common_configure_flags := \\\|common_configure_flags := \\\--add-module=$(cd  nginx-rtmp-module && pwd) \\\|" debian/rules && \
    cat debian/rules && echo "^^" && \
    apt-get -y build-dep nginx && \
    dpkg-buildpackage -b && \
    cd .. && ls -ahl && \
    dpkg --install $(find . -maxdepth 1 -type f -name "nginx-common*") && \
    dpkg --install $(find . -maxdepth 1 -type f -name "libnginx*") && \
    dpkg --install $(find . -maxdepth 1 -type f -name "nginx-full*"); \
    apt-get -y remove software-properties-common dpkg-dev git; \
    apt-get -y install aptitude; \
    aptitude -y markauto $(apt-cache showsrc nginx | sed -e '/Build-Depends/!d;s/Build-Depends: \|,\|([^)]*),*\|\[[^]]*\]//g'); \
    apt-get -y autoremove; \
    apt-get -y remove aptitude; \
    apt-get -y autoremove; \
    rm /etc/nginx/modules-enabled/50-mod-rtmp.conf \
    rm /var/www/html/index.nginx-debian.html; \
    rm -rf ./*nginx*

COPY nginx.conf /etc/nginx/nginx.conf

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443 1935

CMD ["nginx", "-g", "daemon off;"]
