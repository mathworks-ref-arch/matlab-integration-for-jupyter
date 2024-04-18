# Workflows in matlab-integration-for-jupyter

This repository uses workflows to build the Dockerfiles hosted in this repository and publish them to GHCR.

## Overview

There are 2 kinds of YML files used here:
1. `build-and-publish-docker-image.yml`, which specifies a reusable workflow, which MUST be called from a workflow configuration file.
2. Other YML files in the `.github/workflows` directory call this reusable-workflow.

Each of these workflows:
  a. Monitors a specific Dockerfile. For example, the file `matlab-ubuntu20.04-mounted-dockerfile.yml` monitors the Dockerfile `matlab/ubuntu20.04/Dockerfile.mounted`
  b. Is triggered when changes are made to the Dockerfile it monitors. This should build and publish to the configured registries.

## Triggers and Scheduled Jobs

All workflows are scheduled to run on Monday at 00:00.
Workflows are also triggered when you push any changes to the directories with Dockerfiles.
Workflows can be manually triggered from the "Actions" tab.

## Directory structure

The matlab-integration-for-jupyter repository has the following folder structure:

1. matlab : Hosts the Dockerfile that showcase access to matlab through the `jupyter-matlab-proxy` package.
    * matlab/ubuntu20.04 : Hosts the same dockerfiles but with support for `ubuntu20.04`
1. matlab-vnc : Hosts the Dockerfile that showcase access to matlab through the `jupyter-matlab-vnc-proxy` package.
    * matlab-vnc/ubuntu20.04 : Hosts the same dockerfiles but with support for `ubuntu20.04`

## Images Pushed to GHCR:

| Name of Dockerfile | Name of Image Pushed | Tags Available |
|----|----|----|
|matlab/Dockerfile | jupyter-matlab-notebook | r2024a, r2023b, r2023a, r2022b, r2023b-ubuntu22.04, r2023a-ubuntu22.04, r2022b-ubuntu22.04 |
|matlab/Dockerfile.byoi | jupyter-byoi-matlab-notebook | r2024a, r2023b, r2023a, r2022b, r2023b-ubuntu22.04, r2023a-ubuntu22.04, r2022b-ubuntu22.04 |
|matlab/Dockerfile.mounted | jupyter-mounted-matlab-notebook | r2024a, r2023b, r2023a, r2022b, r2023b-ubuntu22.04, r2023a-ubuntu22.04, r2022b-ubuntu22.04 |
|matlab/ubuntu20.04/Dockerfile | jupyter-matlab-notebook | r2023b-ubuntu20.04, r2023a-ubuntu20.04, r2020b-ubuntu20.04, r2020a-ubuntu20.04, r2021b-ubuntu20.04, r2021a-ubuntu20.04, r2020b-ubuntu20.04 |
|matlab/ubuntu20.04/Dockerfile.byoi | jupyter-byoi-matlab-notebook | r2023b-ubuntu20.04, r2023a-ubuntu20.04, r2020b-ubuntu20.04, r2020a-ubuntu20.04, r2021b-ubuntu20.04, r2021a-ubuntu20.04, r2020b-ubuntu20.04 |
|matlab/ubuntu20.04/Dockerfile.mounted | jupyter-mounted-matlab-notebook |r2023b-ubuntu20.04, r2023a-ubuntu20.04, r2020b-ubuntu20.04, r2020a-ubuntu20.04, r2021b-ubuntu20.04, r2021a-ubuntu20.04, r2020b-ubuntu20.04 |
|matlab-vnc/Dockerfile | jupyter-matlab-vnc-notebook | r2024a, r2023b, r2023a, r2022b, r2023b-ubuntu22.04, r2023a-ubuntu22.04, r2022b-ubuntu22.04 |
|matlab-vnc/Dockerfile.mounted | jupyter-mounted-matlab-vnc-notebook | r2024a, r2023b, r2023a, r2022b, r2023b-ubuntu22.04, r2023a-ubuntu22.04, r2022b-ubuntu22.04 |
|matlab-vnc/ubuntu20.04/Dockerfile | jupyter-matlab-vnc-notebook | r2023b-ubuntu20.04, r2023a-ubuntu20.04, r2020b-ubuntu20.04, r2020a-ubuntu20.04, r2021b-ubuntu20.04, r2021a-ubuntu20.04, r2020b-ubuntu20.04 |
|matlab-vnc/ubuntu20.04/Dockerfile.mounted | jupyter-mounted-matlab-vnc-notebook | r2023b-ubuntu20.04, r2023a-ubuntu20.04, r2020b-ubuntu20.04, r2020a-ubuntu20.04, r2021b-ubuntu20.04, r2021a-ubuntu20.04, r2020b-ubuntu20.04 |

Note: Pascal cased tags are also made available. ie: r2023a-ubuntu20.04 will also have a `R`2023a-ubuntu20.04

Each `reusable-workflow` job consists of the following steps:

1. Check-out the repository into a GitHub Actions runner.
1. Setup Image Tags: Configures tags to have both Pascal & camel case tags (R2023a, r2023a)
1. Login to DockerHub Container Registry
1. Build the image & push 
1. If the variable "should_add_latest_tag" is present that an additional "latest" tag is added to the image.

----

Copyright 2023-2024 The MathWorks, Inc.

----
