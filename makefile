.PHONY: TBD
include .env
CERT_COUNTRY=CA
CERT_STATE=Ontario
CERT_LOC=Toronto
CERT_ORG=DigiHunch
CERT_OU=Imaging
CERT_DAYS=1095

dev: dep1 certs local done 
aws: dep1 dep2 certs psql ec2 done

dep1:
	$(info --- Checking Dependencies for dev deployment ---)
	@if ! command -v docker &> /dev/null; then echo "Docker is not installed. Please install Docker."; exit 1; fi
	@echo [makefile] dependency check for dev passed!
dep2:
	$(info --- Checking Dependencies for non-dev deployment ---)
	@if ! command -v jq &> /dev/null; then echo "jq is not installed. Please install jq."; exit 1; fi
	@if ! command -v yq &> /dev/null; then echo "yq is not installed. Please install yq."; exit 1; fi
	@if ! command -v psql &> /dev/null; then echo "postgresql is not installed. Please install postgresql."; exit 1; fi
	@echo [makefile] dependency check for non-dev passed!
certs:
	$(info --- Creating Self-signed Certificates ---)
	@echo [makefile] starting to create self-signed certificate for $(SITE_NAME) in config/certs
	@openssl req -x509 -sha256 -newkey rsa:4096 -days $(CERT_DAYS) -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=issuer.$(SITE_NAME)/emailAddress=info@$(SITE_NAME) -keyout config/certs/ca.key -out config/certs/ca.crt 2>/dev/null
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=$(SITE_NAME)/emailAddress=issuer@$(SITE_NAME) -addext extendedKeyUsage=serverAuth -addext subjectAltName=DNS:$(SITE_NAME),DNS:issuer.$(SITE_NAME) -keyout config/certs/server.key -out config/certs/server.csr 2>/dev/null
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/server.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/server.crt
	@cat config/certs/server.key config/certs/server.crt config/certs/ca.crt > config/certs/$(SITE_NAME).pem
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=client.$(SITE_NAME)/emailAddress=client@$(SITE_NAME) -keyout config/certs/client.key -out config/certs/client.csr 2>/dev/null
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/client.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/client.crt
	@echo [makefile] finished creating self-signed certificate
local:
	$(info --- Configuring Orthanc for local dev ---)
	@cp config/orthanc/orthanc.json.local config/orthanc/orthanc.json
	@cp docker-compose.yaml.local docker-compose.yaml
psql:
	$(info --- Provisioning PostgreSQL database for Keycloak on RDS ---)
	@sed s/keycloak_db/$(KC_DB_NAME)/g config/keycloak_db/keycloak-provision.sql.tmpl > config/keycloak_db/keycloak-provision.sql
	@export PGPASSWORD=$(KC_DB_PASSWORD); psql "host=$(KC_DB_HOST) port=5432 user=$(KC_DB_USERNAME) dbname=postgres sslmode=require" -f config/keycloak_db/keycloak-provision.sql
	@echo [makefile] initialized postgresdb for keycloak
ec2:
	$(info --- Configuring Orthanc on EC2 with S3 and RDS storage ---) 
	@jq '.AwsS3Storage = {ConnectionTimeout: 30, RequestTimeout: 1200, RootPath: "image_arvhie", StorageStructure: "flat", BucketName: "$(S3_BUCKET)", Region: "$(S3_REGION)"} | del(.StorageDirectory) | .PostgreSQL.EnableSsl = true | .Plugins += ["/usr/share/orthanc/plugins-available/libOrthancAwsS3Storage.so"] ' config/orthanc/orthanc.json.local > config/orthanc/orthanc.json
	@yq e 'del(.services.keycloak-db, .services.orthanc-db) | .services.orthanc-service.depends_on |= map(select(. != "orthanc-db")) | .services.keycloak-service.depends_on |= map(select(. != "keycloak-db")) | .services.keycloak-service.environment.KC_DB_URL += "?ssl=true&sslmode=require" ' docker-compose.yaml.local > docker-compose.yaml
	@echo [makefile] updated configuration on ec2 
done:
	$(info --- Configuration completed ---)
	@echo [makefile] launch the application with docker compose up
