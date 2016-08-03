FROM centos


RUN yum update -y
RUN yum install -y curl which wget ntp ntpdate ntp-doc unzip system-config-services


WORKDIR /install

ADD install-centos.sh /install
RUN bash /install/install-centos.sh

# http
EXPOSE 80
EXPOSE 443

# sip
EXPOSE 5060
EXPOSE 5061

# snmp
EXPOSE 161

# tftp
EXPOSE 69

# ldap
EXPOSE 369

CMD ["/usr/local/pbx/pbxctrl", "--no-daemon", "--dir", "/usr/local/pbx", "--http-port", "80", "--https-port", "433"]
