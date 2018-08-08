.PHONY: autoscale create delete createrc deleterc createjmxconfig deletejmxconfig

TIMESTAMP=tmp-$(shell date +%s )

autoscale:
	kubectl autoscale deployment hazelcast --cpu-percent=70 --min=3 --max=100

create:
	kubectl create -f deployment.yaml

createingress:
		kubectl create -f hazelcast-ingress.yaml

deleteingress:
				kubectl delete -f hazelcast-ingress.yaml

createservice:
		kubectl create -f hazelcast-service.yaml

deleteservice:
				kubectl delete -f hazelcast-service.yaml

delete:
	kubectl delete -f deployment.yaml

createrc:
	kubectl create -f deployrc.yaml

deleterc:
	kubectl delete -f deployrc.yaml

createjmxconfig:
	kubectl create -f jmx-configmap.yaml

deletejmxconfig:
	kubectl delete -f jmx-configmap.yaml
