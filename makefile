###
### Global Variables
###

helm_chart_name = wettkampfdb-maintenance
repository_path = ~/github/wettkampfdb-maintenance
chart_path 			= ~/github/wettkampfdb-maintenance/helmchart
catalog_path 		= ~/github/wettkampfdb-helm-catalog

internal_port 	= 8080
local_port 			= 8080

###
### Actions for Docker
###

build: 
	docker build -t $(helm_chart_name) .

run:
	docker run -i -t --rm \
		--hostname=$(helm_chart_name) \
		--publish=$(local_port):$(internal_port) \
		--name="$(helm_chart_name)" \
		$(helm_chart_name)

up: build run

### 
### Actions for Kubernetes
###

watch:
	watch kubectl get all

forward: 
	kubectl port-forward --namespace default svc/$(helm_chart_name) $(local_port):$(internal_port)

### 
### Actions for Helm
###

template:
	cd helmchart; helm template $(helm_chart_name) .

install:
	helm install $(helm_chart_name) $(chart_path) --values $(chart_path)/values.yaml

uninstall:
	helm uninstall $(helm_chart_name)

reinstall: 
	-make uninstall 
	-make install

###
### Utils
###

release:
	echo  

minikube:
	minikube start
	minikube dashboard

regcred: 
	kubectl create secret docker-registry registry-cred --docker-server=docker.pkg.github.com --docker-username="$(GITHUB_USERNAME)" --docker-password="$(GITHUB_TOKEN)"

package:
	cd $(catalog_path); helm package --debug $(repository_path)/helmchart/
	cd $(catalog_path); helm repo index .
	cd $(catalog_path); git pull
	cd $(catalog_path); git add .
	cd $(catalog_path); git commit -m "Catalog update"
	cd $(catalog_path); git push origin master

