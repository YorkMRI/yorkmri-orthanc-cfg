.PHONY: TBD
include .env
CERT_COUNTRY=CA
CERT_STATE=Ontario
CERT_LOC=Toronto
CERT_ORG=DigiHunch
CERT_OU=Imaging
CERT_DAYS=1095

local: dep certs done 
ec2: dep certs

dep:
	$(info --- Checking Dependencies ---)
	@if ! command -v docker &> /dev/null; then echo "Docker is not installed. Please install Docker."; exit 1; fi
	@if ! command -v jq &> /dev/null; then echo "jq is not installed. Please install jq."; exit 1; fi
	@if ! command -v yq &> /dev/null; then echo "yq is not installed. Please install yq."; exit 1; fi
	@echo [makefile] dependency check passed!
certs:
	$(info --- Creating Self-signed Certificates ---)
	@echo [makefile] starting to create self-signed certificate for $(SITE_NAME) in config/certs
	@openssl req -x509 -sha256 -newkey rsa:4096 -days $(CERT_DAYS) -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=issuer.$(SITE_NAME)/emailAddress=info@$(SITE_NAME) -keyout config/certs/ca.key -out config/certs/ca.crt
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=$(SITE_NAME)/emailAddress=issuer@$(SITE_NAME) -addext extendedKeyUsage=serverAuth -addext subjectAltName=DNS:$(SITE_NAME),DNS:issuer.$(SITE_NAME) -keyout config/certs/server.key -out config/certs/server.csr
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/server.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/server.crt
	@cat config/certs/server.key config/certs/server.crt config/certs/ca.crt > config/certs/$(SITE_NAME).pem
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=client.$(SITE_NAME)/emailAddress=client@$(SITE_NAME) -keyout config/certs/client.key -out config/certs/client.csr
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/client.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/client.crt
	@echo [makefile] finished creating self-signed certificate
aws:
	$(info --- Configuring Orthanc on EC2 with S3 and RDS storage ---) 
	@mv config/orthanc/orthanc.json config/orthanc/orthanc_orig.json
	@jq --argjson s3_child "$(cat config/orthanc/s3_cfg.json)" '. + $s3_child | del(.StorageDirectory)' config/orthanc/orthanc_orig.json > config/orthanc/orthanc.json
	@mv docker-compose.yaml docker-compose-orig.yaml
	@yq e 'del(.services.keycloak-db, .services.orthanc-db) | .services.orthanc-service.environment.S3_BUCKET = "$X" | .services.orthanc-service.environment.S3_REGION = "$Y"' docker-compose-orig.yaml > docker-compose.yaml
done:
	$(info --- Configuration completed ---)
	@echo [makefile] launch the application with docker compose up
