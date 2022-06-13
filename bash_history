git config --global credential.helper cache
lab-configure
git clone https://github.com/mas-ony/DO180-apps
cd DO180-apps
git status 
git checkout -b testbranch
echo "DO180" > TEST
git add .
git commit -am "DO180"
git push --set-upstream origin testbranch
echo "OCP4.6" > TEST
git add .
git commit -am "OCP4.6"
git push
head README.md
cd ~

lab container-create start
podman login registry.redhat.io
podman run --name mysql-basic -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 -d registry.redhat.io/rhel8/mysql-80:1
podman ps --format "{{.ID}} {{.Image}} {{.Names}}"
podman exec -it mysql-basic /bin/bash
lab container-create finish

lab container-rootless start
sudo podman run --rm --name asroot -ti registry.access.redhat.com/ubi8:latest /bin/bash
sudo ps -ef | grep "sleep 1000"
podman run --rm --name asuser -ti registry.access.redhat.com/ubi8:latest /bin/bash
sudo ps -ef | grep "sleep 2000" | grep -v grep
lab container-rootless finish

lab container-review start
podman run --name httpd-basic -p 8080:80 -d quay.io/redhattraining/httpd-parent:2.4
podman container list
podman exec -it b830d6c34837 bash
curl http://0.0.0.0:8080
lab container-review grade
lab container-review finish

lab manage-lifecycle start
podman login registry.redhat.io
podman run --name mysql-db registry.redhat.io/rhel8/mysql-80:1
podman logs mysql-db
podman run --name mysql -d -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 registry.redhat.io/rhel8/mysql-80:1
podman ps --format="{{.ID}} {{.Names}} {{.Status}}"
podman cp /home/student/DO180/labs/manage-lifecycle/db.sql mysql:/
podman exec mysql /bin/bash -c 'mysql -uuser1 -pmypa55 items < /db.sql'
podman run --name mysql-2 -it registry.redhat.io/rhel8/mysql-80:1 /bin/bash
podman ps -a --format="{{.ID}} {{.Names}} {{.Status}}"
podman exec mysql /bin/bash -c 'mysql -uuser1 -pmypa55 -e "select * from items.Projects;"'
lab manage-lifecycle finish

lab manage-storage start
mkdir -pv /home/student/local/mysql
sudo semanage fcontext -a -t container_file_t '/home/student/local/mysql(/.*)?'
sudo restorecon -R /home/student/local/mysql
ls -ldZ /home/student/local/mysql
podman unshare chown 27:27 /home/student/local/mysql
podman login registry.redhat.io
podman pull registry.redhat.io/rhel8/mysql-80:1
podman run --name persist-db -d -v /home/student/local/mysql:/var/lib/mysql/data -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 registry.redhat.io/rhel8/mysql-80:1
podman ps --format="{{.ID}} {{.Names}} {{.Status}}"
ls -ld /home/student/local/mysql/items
podman unshare ls -ld /home/student/local/mysql/items
lab manage-storage finish

lab manage-networking start
podman login registry.redhat.io
podman run --name mysqldb-port -d -v /home/student/local/mysql:/var/lib/mysql/data -p 13306:3306 -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 registry.redhat.io/rhel8/mysql-80:1
podman ps --format="{{.ID}} {{.Names}} {{.Ports}}"
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P13306 items < /home/student/DO180/labs/manage-networking/db.sql
podman exec -it mysqldb-port mysql -uroot items -e "SELECT * FROM Item"
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P13306 items -e "SELECT * FROM Item"
podman exec -it mysqldb-port /bin/bash
lab manage-networking finish

lab manage-review start
mkdir -pv /home/student/local/mysql
sudo semanage fcontext -a -t container_file_t '/home/student/local/mysql(/.*)?'
sudo restorecon -R /home/student/local/mysql
ls -ldZ /home/student/local/mysql
podman unshare chown 27:27 /home/student/local/mysql
podman run --name mysql-1 -d -v /home/student/local/mysql:/var/lib/mysql/data -p 13306:3306 -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 registry.redhat.io/rhel8/mysql-80:1
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P13306 items < /home/student/DO180/labs/manage-review/db.sql
podman stop mysql-1
podman ps -a --format="{{.ID}} {{.Names}} {{.Ports}}"
podman run --name mysql-2 -d -v /home/student/local/mysql:/var/lib/mysql/data -p 13306:3306 -e MYSQL_USER=user1 -e MYSQL_PASSWORD=mypa55 -e MYSQL_DATABASE=items -e MYSQL_ROOT_PASSWORD=r00tpa55 registry.redhat.io/rhel8/mysql-80:1
podman ps -a --format="{{.ID}} {{.Names}} {{.Ports}}"
podman ps -a --format="{{.ID}} {{.Names}} {{.Ports}}" >> /tmp/my-containers
podman exec -it mysql-2 /bin/bash
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P13306 items -e "INSERT INTO Item (description, done) VALUES('Finished lab', 1);"
podman rm mysql-1
lab manage-review grade
lab manage-review finish

lab image-operations start
podman login quay.io
podman run -d --name official-httpd -p 8180:80 quay.io/redhattraining/httpd-parent
podman exec -it official-httpd /bin/bash
curl 127.0.0.1:8180/do180.html
podman diff official-httpd
podman stop official-httpd
podman commit -a 'ony' official-httpd do180-custom-httpd
podman images
source /usr/local/etc/ocp4.config 
podman tag do180-custom-httpd quay.io/${RHT_OCP4_QUAY_USER}/do180-custom-httpd:v1.0
podman images
podman push quay.io/${RHT_OCP4_QUAY_USER}/do180-custom-httpd:v1.0
podman pull -q quay.io/${RHT_OCP4_QUAY_USER}/do180-custom-httpd:v1.0
podman run -d --name test-httpd -p 8280:80 ${RHT_OCP4_QUAY_USER}/do180-custom-httpd:v1.0
curl http://localhost:8280/do180.html
lab image-operations finish

lab image-review start
podman pull quay.io/redhattraining/nginx:1.17
podman run -d --name official-nginx -p 8080:80 quay.io/redhattraining/nginx:1.17
podman exec official-nginx /bin/bash -c "echo 'DO180' > /usr/share/nginx/html/index.html"
curl http://localhost:8080/index.html
podman stop official-nginx 
podman commit -a 'ony' official-nginx do180/mynginx:v1.0-SNAPSHOT
podman run -d --name official-nginx-dev -p 8080:80 do180/mynginx:v1.0-SNAPSHOT
podman exec official-nginx-dev /bin/bash -c "echo 'DO180 Page' > /usr/share/nginx/html/index.html"
curl http://localhost:8080/index.html
podman stop official-nginx-dev 
podman commit -a 'ony' official-nginx-dev do180/mynginx:v1.0
podman image rm -f do180/mynginx:v1.0-SNAPSHOT
podman run -d --name my-nginx -p 8280:80 do180/mynginx:v1.0
curl http://localhost:8280/index.html
lab image-review grade
lab image-review finish

lab dockerfile-create start
nano /home/student/DO180/labs/dockerfile-create/Containerfile
cd /home/student/DO180/labs/dockerfile-create
podman build --layers=false -t do180/apache .
podman images
podman run --name lab-apache -d -p 10080:80 do180/apache
podman ps
curl 127.0.0.1:10080
lab dockerfile-create finish

lab dockerfile-review start
cd /home/student/DO180/labs/dockerfile-review/
nano Containerfile 
podman build --layers=false -t do180/custom-apache .
podman run --name containerfile -d -p 20080:8080 do180/custom-apache
curl 127.0.0.1:20080
lab dockerfile-review grade
lab dockerfile-review finish

lab openshift-resources start
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-mysql-openshift
oc new-app --template=mysql-persistent -p MYSQL_USER=user1 -p MYSQL_PASSWORD=mypa55 -p MYSQL_DATABASE=testdb -p MYSQL_ROOT_PASSWORD=r00tpa55 -p VOLUME_CAPACITY=10Gi
oc status
oc get pods
oc describe pod mysql-1-s9r4h 
oc get svc
oc describe service mysql
oc get pvc
oc describe pvc/mysql
oc port-forward mysql-1-s9r4h 3306:3306
mysql -uuser1 -pmypa55 --protocol tcp -h localhost
oc delete-project ${RHT_OCP4_DEV_USER}-mysql-openshift
oc delete project bpcoud-mysql-openshift
lab openshift-resources finish

lab openshift-routes start
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-route
oc new-app --docker-image=quay.io/redhattraining/php-hello-dockerfile --name php-helloworld
oc get pods -w
oc logs -f php-helloworld-74bb86f6cb-b7xb8 
oc describe svc/php-helloworld
oc expose svc/php-helloworld
oc describe route
curl php-helloworld-${RHT_OCP4_DEV_USER}-route.${RHT_OCP4_WILDCARD_DOMAIN}
oc delete route/php-helloworld
oc expose svc/php-helloworld --name=${RHT_OCP4_DEV_USER}-xyz
oc describe route
curl ${RHT_OCP4_DEV_USER}-xyz-${RHT_OCP4_DEV_USER}-route.${RHT_OCP4_WILDCARD_DOMAIN}
curl bpcoud-xyz-bpcoud-route.apps.ap46a.prod.ole.redhat.com
lab openshift-routes finish

lab openshift-s2i start
cd ~/DO180-apps
git checkout master
git checkout -b s2i
git push -u origin s2i
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-s2i
oc new-app php:7.3 --name=php-helloworld https://github.com/${RHT_OCP4_GITHUB_USER}/DO180-apps#s2i --context-dir php-helloworld
oc get pods
oc logs --all-containers -f php-helloworld-1-build
oc describe deployment/php-helloworld
oc expose service php-helloworld --name ${RHT_OCP4_DEV_USER}-helloworld
oc get route -o jsonpath='{..spec.host}{"\n"}'
curl -s ${RHT_OCP4_DEV_USER}-helloworld-${RHT_OCP4_DEV_USER}-s2i.${RHT_OCP4_WILDCARD_DOMAIN}
cd ~/DO180-apps/php-helloworld
nano index.php 
git add .
git commit -m 'Changed index page contents.'
git push origin s2i
oc start-build php-helloworld
oc logs php-helloworld-2-build -f
oc get pods
curl -s ${RHT_OCP4_DEV_USER}-helloworld-${RHT_OCP4_DEV_USER}-s2i.${RHT_OCP4_WILDCARD_DOMAIN}
lab openshift-s2i finish

lab openshift-webconsole start
cd ~/DO180-apps
git checkout master
git checkout -b console
git push -u origin console
source /usr/local/etc/ocp4.config
echo $RHT_OCP4_WILDCARD_DOMAIN
cd ~/DO180-apps/php-helloworld
nano index.php 
git add index.php
git commit -m 'updated app'
git push origin console
lab openshift-webconsole finish

lab openshift-review start
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-ocp
oc new-app php:7.3~https://github.com/RedHatTraining/DO180-apps --context-dir temps --name temps
oc logs -f bc/temps
oc get pods -w
oc expose svc/temps
oc get route/temps
lab openshift-review grade
lab openshift-review finish

lab multicontainer-design start
podman login registry.redhat.io
cd ~/DO180/labs/multicontainer-design/deploy/nodejs
nano Containerfile 
ip -br addr list | grep eth0
nano ./nodejs-source/models/db.js 
nano ./build.sh 
./build.sh
podman images --format "table {{.ID}} {{.Repository}} {{.Tag}}"
cd networked/
nano run.sh 
./run.sh
podman ps --format="table {{.ID}} {{.Names}} {{.Image}} {{.Status}}"
mysql -uuser1 -h 172.25.250.9 -pmypa55 -P30306 items < /home/student/DO180/labs/multicontainer-design/deploy/nodejs/networked/db.sql
podman exec -it todoapi env
curl -w "\n" http://127.0.0.1:30080/todo/api/items/1
cd ~
lab multicontainer-design finish

lab multicontainer-application start
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-application
cd ./DO180/labs/multicontainer-application/
nano todo-app.yml 
oc create  -f todo-app.yml 
oc get pods -w
oc port-forward mysql 3306:3306
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P3306 items < db.sql
oc expose service todoapi
oc status | grep -o "http:.*com"
curl -w "\n" $(oc status | grep -o "http:.*com")/todo/api/items/1
cd ~
lab multicontainer-application finish

lab multicontainer-openshift start
source /usr/local/etc/ocp4.config
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-template
cd ./DO180/labs/multicontainer-openshift/
nano todo-template.json 
oc process -f todo-template.json | oc create -f -
oc get pods -w
oc port-forward mysql 3306:3306
mysql -uuser1 -h 127.0.0.1 -pmypa55 -P3306 items < db.sql
oc expose service todoapi
oc status | grep -o "http:.*com"
curl -w "\n" $(oc status | grep -o "http:.*com")/todo/api/items/1
cd ~
lab multicontainer-openshift finish

lab multicontainer-review start
source /usr/local/etc/ocp4.config
podman login registry.redhat.io
podman login quay.io
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-deploy
cd ~/DO180/labs/multicontainer-review/
cd ./images/mysql/
./build.sh 
podman images
podman tag do180-mysql-80-rhel8 quay.io/${RHT_OCP4_QUAY_USER}/do180-mysql-80-rhel8
podman push quay.io/${RHT_OCP4_QUAY_USER}/do180-mysql-80-rhel8
cd ~/DO180/labs/multicontainer-review/
cd ./images/quote-php/
./build.sh 
podman images
podman tag quote-php quay.io/${RHT_OCP4_QUAY_USER}/do180-quote-php
podman push quay.io/${RHT_OCP4_QUAY_USER}/do180-quote-php
cd ~/DO180/labs/multicontainer-review/
nano quote-php-template.json 
oc process -p RHT_OCP4_QUAY_USER=mas_ony -f quote-php-template.json | oc create -f -
oc get pods -w
oc expose service quote-php 
oc status | grep -o "http:.*com"
curl -w "\n" $(oc status | grep -o "http:.*com")
cd ~
lab multicontainer-review grade
lab multicontainer-review finish

lab troubleshoot-s2i start
source /usr/local/etc/ocp4.config
cd ~/DO180-apps/
git checkout master
git checkout -b troubleshoot-s2i
git push -u origin troubleshoot-s2i
oc login -u "${RHT_OCP4_DEV_USER}" -p "${RHT_OCP4_DEV_PASSWORD}"
oc new-project ${RHT_OCP4_DEV_USER}-nodejs
oc new-app --context-dir=nodejs-helloworld https://github.com/${RHT_OCP4_GITHUB_USER}/DO180-apps#troubleshoot-s2i -i nodejs:12 --name nodejs-hello --build-env npm_config_registry=http://${RHT_OCP4_NEXUS_SERVER}/repository/npm-proxy
oc get pods -w
oc logs bc/nodejs-hello
nano nodejs-helloworld/package.json 
git commit -am "Fixed Express release"
git push
oc start-build bc/nodejs-hello
oc logs -f bc/nodejs-hello
oc get pods
oc logs nodejs-hello-75d8bff96-924vf
nano nodejs-helloworld/package.json 
git commit -am "Added start up script"
git push
oc start-build bc/nodejs-hello
oc get pods -w
oc logs nodejs-hello-794b5b785c-4zjjr 
oc expose svc/nodejs-hello
oc get route -o yaml
curl -w "\n" http://nodejs-hello-${RHT_OCP4_DEV_USER}-nodejs.${RHT_OCP4_WILDCARD_DOMAIN}
lab troubleshoot-s2i finish

lab troubleshoot-container start
cd ~/DO180/labs/troubleshoot-container/
nano ./conf/httpd.conf 
podman build -t troubleshoot-container .
podman images
cd ~
podman run --name troubleshoot-container -d -p 10080:80 troubleshoot-container
podman logs -f troubleshoot-container
curl http://127.0.0.1:10080
lab troubleshoot-container finish

lab troubleshoot-review start
source /usr/local/etc/ocp4.config
cd ~/DO180-apps
git checkout master
git checkout -b troubleshoot-review
git push -u origin troubleshoot-review
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-nodejs-app
oc new-app --context-dir=nodejs-app https://github.com/${RHT_OCP4_GITHUB_USER}/DO180-apps#troubleshoot-review -i nodejs:12 --name nodejs-dev --build-env npm_config_registry=http://${RHT_OCP4_NEXUS_SERVER}/repository/npm-proxy
oc get pods -w
oc logs bc/nodejs-dev
nano nodejs-app/package.json
git commit -am "Fixed Express release"
git push
oc start-build bc/nodejs-dev
oc logs -f bc/nodejs-dev
oc get pods
oc logs nodejs-dev-566cc6bb8-866xn
nano nodejs-app/server.js
git commit -am "Fixed Express release"
git push
oc start-build bc/nodejs-dev
oc logs -f bc/nodejs-dev
oc get pods
oc logs nodejs-dev-6c7fb77dbf-qbmfc
oc expose svc/nodejs-dev
oc get route -o yaml
curl -w "\n" http://nodejs-dev-${RHT_OCP4_DEV_USER}-nodejs-app.${RHT_OCP4_WILDCARD_DOMAIN}
nano nodejs-app/server.js
git commit -am "Fixed Express release"
git push
oc start-build bc/nodejs-dev
oc logs -f bc/nodejs-dev
oc get pods
oc logs nodejs-dev-78fcfbc56c-d462d
curl -w "\n" http://nodejs-dev-${RHT_OCP4_DEV_USER}-nodejs-app.${RHT_OCP4_WILDCARD_DOMAIN}
lab troubleshoot-review grade
lab troubleshoot-review finish

lab comprehensive-review start
source /usr/local/etc/ocp4.config
cd ./DO180/labs/comprehensive-review/image
./get-nexus-bundle.sh
nano Containerfile
podman build --layers=false -t nexus .
cd ../deploy/local
./run-persistent.sh
podman ps --format="{{.ID}} {{.Names}} {{.Image}}"
podman logs relaxed_goodall | grep JettyServer
curl -v 127.0.0.1:18081/nexus/ 2>&1 | grep -E 'HTTP|<title>'
podman rm -f relaxed_goodall
podman login -u ${RHT_OCP4_QUAY_USER} quay.io
podman push localhost/nexus:latest quay.io/${RHT_OCP4_QUAY_USER}/nexus:latest
cd ../../deploy/openshift
oc login -u ${RHT_OCP4_DEV_USER} -p ${RHT_OCP4_DEV_PASSWORD} ${RHT_OCP4_MASTER_API}
oc new-project ${RHT_OCP4_DEV_USER}-review
export RHT_OCP4_QUAY_USER
envsubst < resources/nexus-deployment.yaml | oc create -f -
oc get pods -w
oc expose svc/nexus
oc get route -o yaml
curl -w "\n" http://nexus-${RHT_OCP4_DEV_USER}-review.${RHT_OCP4_WILDCARD_DOMAIN}
lab comprehensive-review grade
lab comprehensive-review finish

