FROM ubuntu:quantal
MAINTAINER Manfred Touron <m@42.am>

RUN apt-get update
RUN apt-get -y install openssh-server
RUN apt-get -y install git mysql-client apache2 libapache2-mod-php5 pwgen python-setuptools vim-tiny php5-mysql php-apc php5-gd php5-memcache memcached drush mc
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

RUN apt-get clean
RUN sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf
RUN easy_install supervisor

RUN rm -rf /var/www/ && cd /var && drush dl drupal && mv /var/drupal*/ /var/www/
RUN cd /var/www && tar czf sites.tgz sites && rm -rf sites

RUN cd /var/lib && tar czf mysql.tgz mysql && rm -rf mysql

RUN mkdir /var/run/sshd
RUN echo "root:root" | chpasswd

RUN mkdir -p /data/
RUN ln -sf /data/sites /var/www/sites

RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
RUN sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
RUN sed -i 's/^datadir.*/datadir = \/data\/mysql/' /etc/mysql/my.cnf
RUN a2enmod rewrite vhost_alias
RUN ln -s /var/www/sites/default /drupal

EXPOSE 80
EXPOSE 22
VOLUMES ["/data"]

ADD ./drushrc.php /root/.drushrc.php
ADD ./start.sh /
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf

RUN chmod 755 /start.sh /etc/apache2/foreground.sh

CMD ["/bin/bash", "/start.sh"]
