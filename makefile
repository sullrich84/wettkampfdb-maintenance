###
### Global Variables
###

helm_chart_name = wdb-maintenance
repository_path = ~/github/wettkampfdb-maintenance
chart_path 			= ~/github/wettkampfdb-maintenance/helm

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

minikube:
	minikube start
	minikube dashboard