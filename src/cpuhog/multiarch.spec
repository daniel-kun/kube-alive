image: danielkun/cpuhog:latest
manifests:
  -
    image: danielkun/cpuhog_arm32v7
    platform:
      architecture: arm
      os: linux
  -
    image: danielkun/cpuhog_amd64
    platform:
      architecture: amd64
      os: linux

