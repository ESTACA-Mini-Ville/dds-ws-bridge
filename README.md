# dds-ws-bridge

Lightweight bridge that forwards DDS topics to WebSocket clients using eProsima Integration Service + Fast-DDS.

This repository provides a Docker-ready wrapper that builds and runs the eProsima Integration Service (IS) workspace and exposes a WebSocket server which forwards DDS topics to connected WebSocket clients in JSON.

## What it does

- Launches the Integration Service configured by `dds_to_ws.yaml`.
- Uses Fast-DDS for DDS connectivity (configuration via `fastdds_profile.xml`).
- Serves a WebSocket endpoint (default port 80 inside container; mapped to host 8080 in `docker-compose.yml`) that clients can subscribe to and receive topic messages encoded as JSON.
- Provides a tiny `debug_client.html` to test subscriptions from a browser.

## Quick start (Docker)

Recommended: use the included `docker-compose.yml` which builds the image and runs the service.

1. Build and start with docker-compose (from repository root):

```
docker compose up --build -d
```

2. Confirm the container is running:

```
docker ps | grep websocket_server
```

3. Open `debug_client.html` in a browser (or point a WebSocket client to `ws://localhost:8080`) and subscribe to a topic. The example client subscribes to `amcl_pose`.

Notes about the docker-compose setup:

- The compose file mounts several files into the container:
  - `fastdds_profile.xml` -> `/root/fastdds_profile.xml` (used by Fast-DDS)
  - `entrypoint.sh` -> `/usr/local/bin/entrypoint.sh` (container entrypoint)
  - `types/` -> `/root/types` (IDL/type definitions)
  - `dds_to_ws.yaml` -> `/root/dds_to_ws.yaml` (IS configuration)
- The environment variable `FASTRTPS_DEFAULT_PROFILES_FILE` is set to `/root/fastdds_profile.xml` in `docker-compose.yml`.

## Configuration overview

- `dds_to_ws.yaml` — maps DDS topics -> WebSocket endpoints, and declares message types and routing. Example content:

```
types:
 idls:
 - >
  #include <geometry_msgs/PoseWithCovarianceStamped.idl>
 paths: [ "./types/" ]
systems:
 ws:
  type: websocket_server
  port: 80
  security: none
  encoding: json
 dds: { type: fastdds }
routes:
 dds_to_ws: { from: dds, to: ws }
topics:
 amcl_pose:
  type: "PoseWithCovarianceStamped"
  route: dds_to_ws
```

- `fastdds_profile.xml` — Fast-DDS participant profiles for discovery; useful to configure unicast discovery on networks where multicast is unavailable.

- `types/` — place IDL files or generated types here. The Integration Service will use types to (de)serialize DDS messages. Currently the repository contains a `types/` directory (see `types/README.md`).

## Running locally (development)

If you prefer to run the Integration Service locally (not inside Docker), you need to build the IS workspace and source the environment. The project's Dockerfile shows the steps used in the container: it builds Fast-DDS and the Integration Service with `colcon`.

Basic steps (high-level):

1. Install build dependencies (colcon, compilers, git, etc.).
2. Clone the required repositories into a workspace (see `Dockerfile` for repos cloned by the container).
3. Build with `colcon build` and source `install/setup.bash`.
4. Run the Integration Service with the provided config:

```
integration-service ./dds_to_ws.yaml
```

## Testing

- Browser: open `debug_client.html` and check the developer console and Network tab. The page connects to `ws://localhost:8080` and sends a JSON subscribe message:

```
{ op: 'subscribe', topic: 'amcl_pose', type: 'PoseWithCovarianceStamped' }
```

- You can also use any websocket client (wscat, web client) to subscribe and receive messages.

## Environment variables

- FASTRTPS_DEFAULT_PROFILES_FILE — path to the Fast-DDS profile XML (set in `docker-compose.yml` to `/root/fastdds_profile.xml`).

## Debugging

- If the container prints `./is-workspace/install/setup.bash not found` on startup, the Integration Service build step failed. Rebuild the image or check the build logs.
- Check logs with `docker logs websocket_server`.

## Contract

- Inputs: DDS topics available to Fast-DDS; `dds_to_ws.yaml` mapping; IDL types under `types/`.
- Outputs: WebSocket server on port 80 (container) that emits messages to clients in JSON.
- Error modes: missing IDL/type -> messages won't be serialized; misconfigured `fastdds_profile.xml` -> discovery failures; Integration Service not built -> entrypoint will fail.

## License

Project license: see `LICENSE` in repository root.
