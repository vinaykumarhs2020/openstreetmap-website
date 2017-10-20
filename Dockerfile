# FROM ubuntu:16.04
# RUN \
#   sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
#   apt-get update && \
#   apt-get -y upgrade && \
#   apt-get install -y build-essential && \
#   apt-get install -y software-properties-common && \
#   apt-get install -y byobu curl git htop man unzip vim wget && \
#   apt-get install -y locales && \
#   rm -rf /var/lib/apt/lists/*
#
# RUN locale-gen en_GB.utf8 &&\
#   update-locale LANG=en_GB.utf8 LC_ALL=en_GB.utf8
# ENV LANG en_GB.utf8
# ENV LC_ALL en_GB.utf8
#
# # Set environment variables.
# ENV HOME /root
#
# # Define working directory.
# WORKDIR /root
#
# # Define default command.
# CMD ["bash"]

FROM ubuntu:16.04

# RUN apt-get update && \
#   apt-get install -y build-essential && \
#   apt-get install -y software-properties-common && \
#   apt-get install -y locales
#
# RUN locale-gen en_GB.utf8 &&\
#   update-locale LANG=en_GB.utf8 LC_ALL=en_GB.utf8
# ENV LANG en_GB.utf8
# ENV LC_ALL en_GB.utf8
#
# USER root
# WORKDIR /root
# CMD ["/bin/bash"]

# https://docs.docker.com/engine/examples/postgresql_service/#installing-postgresql-on-docker
# RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.3``.
# RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y wget git

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.3
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
 		apt-get install -y apache2 \
										apache2-dev \
										build-essential \
										git-core \
										imagemagick \
										libmagickwand-dev \
										libpq-dev \
										libruby2.3 \
										libsasl2-dev \
										libxml2-dev \
										libxslt1-dev \
										nodejs \
										postgresql-9.6 \
										postgresql-client-9.6 \
										postgresql-contrib-9.6 \
										postgresql-server-dev-all \
										python-software-properties \
										ruby2.3 \
										ruby2.3-dev \
										software-properties-common

RUN gem2.3 install bundler
ADD Gemfile /tmp/Gemfile
WORKDIR /tmp
RUN bundle install
WORKDIR /root
# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.3`` package when it was ``apt-get installed``
USER postgres
# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER root WITH SUPERUSER PASSWORD 'root';" &&\
    createdb -O root root
# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf
# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

USER root
# Expose the PostgreSQL port
EXPOSE 5432
# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/data/openstreetmap-website"]
# Set the default command to run when starting the container
# RUN ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
# RUN ["update-rc.d","postgresql","enable"]
# ENTRYPOINT ["service", "postgresql", "start", "&&", "exec", "$@"]
# ADD provision.sh /usr/local/bin/provision.sh
# RUN chmod +x /usr/local/bin/provision.sh
# CMD ["/bin/bash"]
EXPOSE 3000
ENTRYPOINT ["/data/openstreetmap-website/provision.sh"]
