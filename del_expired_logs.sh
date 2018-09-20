find /opt/J2EE/tomcat-7.0.32-plm2erp/logs/ -mtime +20 -name "localhost_access_log*" -exec rm -rf {} \;
find /opt/J2EE/tomcat-7.0.32-plm2erp/logs/ -mtime +20 -name "wrapper*log" -exec rm -rf {} \;

