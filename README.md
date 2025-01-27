# Orthanc Configuration Repository
This repository was spun off from the orthweb project for the orthanc's application configuration.

## Configure on a Laptop (MacOS or Linux) as development environment

1. Download this repository. If this step has been done by the cloud init script, it would in the current user directory. 
```sh
git clone git@github.com:digihunchinc/orthanc-config.git
```

2. Ensure the required packages are installed. Check `dep1` and `dep2` sections for the specific required packages. 
3. Modify `.env` file to update any username, passwords and image references. Do not use the original password!
4. Go to the project directory, create local configuration file 

```sh
make dev
```
The command should generate `docker-compose.yaml` file based on 

5. Run the following command to bootstrap for the first time, and ensure to monitor the standard output.

```sh
docker compose up
```

When the launch is nearly completed, the standard output from `keycloak-service` should display a line saying:

```
2024-12-21 23:20:49 ########################################################################################
Here is the secret to use for the KEYCLOAK_CLIENT_SECRET env var in the auth service:
qzwffmsgeerdaiglowfhwjxhsotbzrdn
########################################################################################
```
Keep a copy of the `KEYCLOAK_CLIENT_SECRET` value.

5. Go to `docker-compose.yaml` under the environment variables for `orthanc-auth-service`, fill in the `KEYCLOAK_CLIENT_SECRET` value.
```sh
      KEYCLOAK_CLIENT_SECRET: "qzwffmsgeerdaiglowfhwjxhsotbzrdn"
      ENABLE_KEYCLOAK_API_KEYS: "true"    # uncomment after bootstrapping
```
Make sure to have both lines uncommented.

6. Then restart services:

```sh
docker compose down && docker compose up -d
```
Note, when the services are launched, the standard output for `keycloak-backend` may show the following warning:
```
2025-01-26 20:28:18 keycloak-backend       | 2025-01-27 01:28:18,640 WARN  [org.keycloak.events] (executor-thread-1) type="CLIENT_LOGIN_ERROR", realmId="51f8e56b-3df7-4a0e-ae5b-4f961f4a3e78", realmName="orthanc", clientId="admin-cli", userId="null", ipAddress="127.0.0.1", error="invalid_client_credentials", grant_type="client_credentials"
2025-01-26 20:28:18 keycloak-backend       | ### Access denied with the default secret, probably already regenerated. Exiting script...
```
This is normal for the first launch after client secret is set.

The services are exposed on localhost on port 443. The configuration requires using full domain name, such as:
- For Orthanc login: https://orthweb.digihunch.com/orthanc 
- For User Admin: https://orthweb.digihunch.com/keycloak 

Note that using `localhost` as domain name will NOT work. As a workaround, consider editing hosts file `/etc/hosts`, by adding an entry `127.0.0.1 orthweb.digihunch.com`, and bypass browser warnings.

## Configure on an EC2 instance as a test or production environment
Similar to above but use a different make command.
```sh
make aws
```

Check partner specific instructions if your deployment is further customized.