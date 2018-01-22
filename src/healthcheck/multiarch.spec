image: danielkun/healthcheck:latest
manifests:
  -
    image: danielkun/healthcheck_arm32v7
    platform:
      architecture: arm
      os: linux
  -
    image: danielkun/healthcheck_amd64
    platform:
      architecture: amd64
      os: linux

