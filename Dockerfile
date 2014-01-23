FROM moul/tmux
MAINTAINER Manfred Touron <m@42.am>

RUN echo 'deb http://archive.ubuntu.com/ubuntu precise universe main' > /etc/apt/sources.list \
    && apt-get -qq update

RUN apt-get -qq install git mysql-client apache2 \
                    libapache2-mod-php5 supervisor \
                    php5-mysql php-apc php5-gd \
                    php5-memcache memcached drush \
                    curl apache2-utils php-apc \
                    php5-memcache pwgen \
                    && apt-get clean

RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install mysql-server \
                        && apt-get clean


RUN sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf

RUN rm -rf /var/www/ \
    && cd /var \
    && drush dl drupal \
    && mv /var/drupal*/ /var/www/ \
    && cd /var/www \
    && tar czf sites.tgz sites \
    && rm -rf sites \
    && ln -s /var/www/ /drupal \
    && ln -s /var/www/sites/ /sites

RUN cd /var/lib \
    && tar czf mysql.tgz mysql \
    && rm -rf mysql

RUN mkdir -p /data/ \
    && ln -sf /data/sites /var/www/sites

RUN mkdir -p /root/.ssh \
    && ln -sf /data/authorized_keys /root/.ssh/

RUN mkdir -p /root/drush-backups

RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default

RUN sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf \
    && sed -i 's/^datadir.*/datadir = \/data\/mysql/' /etc/mysql/my.cnf

RUN a2enmod rewrite vhost_alias

EXPOSE 80
EXPOSE 22
VOLUME ["/data"]
CMD ["/bin/bash", "/start.sh"]

ADD ./drushrc.php /root/.drushrc.php
ADD ./start.sh /
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf

RUN chmod 755 /start.sh /etc/apache2/foreground.sh
