.PHONY: autoscale create delete cerateloadgenerator generateload deleteloadgenerator

TIMESTAMP=tmp-$(shell date +%s )

autoscale:
	kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

create:
	@eval $$(minikube docker-env) ;\
	kubectl create -f deploy/deployment.yaml

delete:
	kubectl delete -f deploy/deployment.yaml

createloadgenerator:
	kubectl run -i --tty load-generator --image=busybox /bin/sh

deleteloadgenerator:
		kubectl delete deployment load-generator 

generateload:
	@echo "generating load continously"
	$(shell while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done)
