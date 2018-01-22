image: danielkun/frontend:latest
manifests:
  -
    image: danielkun/frontend_arm32v7
    platform:
      architecture: arm
      os: linux
  -
    image: danielkun/frontend_amd64
    platform:
      architecture: amd64
      os: linux

