# Orthanc Configuration Repository
This repository was spun off from the orthweb project for the orthanc's application configuration.

## Configure on a Laptop 

1. Download this repository. This might have been done by cloud init script.
```sh
git clone git@github.com:digihunchinc/orthanc-config.git
```

2. Ensure the required packages are installed. Check `dep1` and `dep2` sections for the specific required packages. 
3. Modify `.env` file to update any username, passwords and image references. Do not use the original password!
4. Go to the project directory, create local configuration file 

```sh
make dev
```

5. run the following command to first bootstrap

```sh
docker compose up
```

The output from `keycloak-service` will show a line saying:

```
2024-12-21 23:20:49 ########################################################################################
Here is the secret to use for the KEYCLOAK_CLIENT_SECRET env var in the auth service:
xyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxy
########################################################################################
```

5. Copy the value and put it in `docker-compose.yaml` under the environment variables for `orthanc-auth-service`:

```sh
      KEYCLOAK_CLIENT_SECRET: "xyzxyzxyzxyzxyzxyzxyzxyzxyzxyzxy"
      ENABLE_KEYCLOAK_API_KEYS: "true"    # uncomment after bootstrapping
```

6. Restart services:

```sh
docker compose down && docker compose up -d
```

## Configure on an EC2 instance
Similar to above but use a different make command.
```sh
make aws
```

Check partner specific instructions if your deployment is further customized.