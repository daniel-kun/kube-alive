image: danielkun/getip:latest
manifests:
  -
    image: danielkun/getip_arm32v7
    platform:
      architecture: arm
      os: linux
  -
    image: danielkun/getip_amd64
    platform:
      architecture: amd64
      os: linux

