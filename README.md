# How to Deploy a kafka cluster using terraform

## Table of Contents

<!-- TOC -->

* [Introduction](#introduction)
* [Architecture](#architecture)
* [Prerequisites](#prerequisites)
  * [Tools](#tools)
  * [Versions](#versions)
* [Deployment](#deployment)
  * [Authenticate gcloud](#authenticate-gcloud)
  * [Configure gcloud settings](#configuring-gcloud-settings)
  * [Setup this project](#setup-this-project)
  * [Provisioning the compute instances](#Provisioning the compute instances)
* [Tear Down](#tear-down)
* [Troubleshooting](#troubleshooting)
* [Relevant Material](#relevant-material)

<!-- TOC -->

## Introduction

This guide demonstrates how to create a kafka cluster with default size `3X3` and kerberos it with kerberos,

Kafka nodes - 3
zookeeper nodes - 3
schema registry - 1
administrator node - 1
kerberos node - 1

## Prerequisites

### Tools
1. [Terraform >= 0.11.10](https://www.terraform.io/downloads.html)
2. [Google Cloud SDK version >= 229.0.0](https://cloud.google.com/sdk/docs/downloads-versioned-archives)
3. bash or bash compatible shell
4. [GNU Make 3.x or later](https://www.gnu.org/software/make/)
5. A Google Cloud Platform project where you have permission to create networks

#### Install Cloud SDK
The Google Cloud SDK is used to interact with your GCP resources.
[Installation instructions](https://cloud.google.com/sdk/downloads) for multiple platforms are available online.

#### Install Terraform

Terraform is used to automate the manipulation of cloud infrastructure. Its
[installation instructions](https://www.terraform.io/intro/getting-started/install.html) are also available online.

## Deployment

The steps below will walk you through using terraform to deploy a Compute Engine cluster that you will then use for working with Kafka.

### Authenticate gcloud

Prior to running this demo, ensure you have authenticated your gcloud client by running the following command:

```console
gcloud auth application-default login
```

### Configure gcloud settings

Run `gcloud config list` and make sure that `compute/zone`, `compute/region` and `core/project` are populated with values that work for you. You can set their values with the following commands:

```console
# Where the region is us-east1
gcloud config set compute/region us-east1

Updated property [compute/region].
```

```console
# Where the zone inside the region is us-east1-c
gcloud config set compute/zone us-east1-c

Updated property [compute/zone].
```

```console
# Where the project name is my-project-name
gcloud config set project my-project-name

Updated property [core/project].
```

### Setup this project

This project requires the following Google Cloud Service APIs to be enabled:

* `compute.googleapis.com`

In addition, the terraform configuration takes three parameters to determine where the compute instances should be created:

* `project`
* `region`
* `zone`

For simplicity, these parameters are to be specified in a file named `terraform.tfvars`, in the `terraform` directory. To ensure the appropriate APIs are enabled and to generate the `terraform/terraform.tfvars` file based on your gcloud defaults, run:

```console
cat terraform/terraform.tfvars

project="YOUR_PROJECT"
region="YOUR_REGION"
zone="YOUR_ZONE"
```

If you need to override any of the defaults, simply replace the desired value(s) to the right of the equals sign(s). Be sure your replacement values are still double-quoted.

### Provisioning the compute instances

Next, apply the terraform configuration with:

```console
# From within the project root, use make to apply the terraform plan
cd terraform \
   && terraform init && \
   && terraform apply --auto-approve
```

## Tear Down

```console
# From within the project root, use make to destroy the terraform plan.
cd terraform \
   && terraform destory --auto-approve
```

## Troubleshooting

### The install script fails with a `Permission denied` when running Terraform

The credentials that Terraform is using do not provide the necessary permissions to create resources in the selected projects. Ensure that the account listed in `gcloud config list` has necessary permissions to create resources. If it does, regenerate the application default credentials using `gcloud auth application-default login`.

## Relevant Material

* [Terraform Google Provider](https://www.terraform.io/docs/providers/google/)
* [Apache Kafka](https://kafka.apache.org/documentation/)
* [Apache Zookeeper](https://zookeeper.apache.org/doc/r3.4.12/index.html)
* [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
* [Grafana](http://docs.grafana.org/)
* [Kerberos](https://web.mit.edu/kerberos/krb5-1.17/doc/index.html)
