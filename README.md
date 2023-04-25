# Hector Benchmarking

This repository contains the scripts and configuration files used to benchmark Hector. We describe here the full
guidelines to reproduce the experiments and compare the results to the paper entitled *Hector: A Framework to Design and
Evaluate Scheduling Strategies in Persistent Key-Value Stores* and submitted to ICPP 2023.

## Installation

### Local Install

#### Installing R Packages

Make sure that R is installed on your local computer:

```shell
> R --version
R version 4.2.2 Patched (2022-11-10 r83330) -- "Innocent and Trusting"
Copyright (C) 2022 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)
```



* tidyverse 1.3.2
* tikzDevice 0.12.3.1

### Getting Access to Grid'5000

The benchmarks are meant to run on the Grid'5000 testbed, which is a French experimental platform. We detail the
procedure below to get access to Grid'5000:

1. Request an account here: https://www.grid5000.fr/w/Grid5000:Get_an_account. Follow the provided guidelines, i.e.,
request a regular account if you are an academic in France. Otherwise, request an Open Access account. In any case, if 
you do not already have a Grid'5000 account, it is important to mention in the *Intended usage* form that you plan to
use Grid'5000 to reproduce experiments as part of the Reproducibility Initiative of ICPP.
2. Once your account has been created, we recommend to read at least the 3 first sections of the *Getting Started* page
to understand how to connect to a Grid'5000 frontend: https://www.grid5000.fr/w/Getting_Started.
3. When everything is setup, connect to Nancy's frontend, where we will install the required environment of the
benchmarking system.

### Downloading the Archive on Grid'5000

Once you succeed to connect to Nancy's frontend, download the current archive to the remote node. Several options are
possible to transfer the archive from your local computer to the remote node (e.g., `scp` or `rsync`), but we recommend
to clone the Git repository directly from Grid'5000:

```shell
<username>@fnancy:~$ git clone <repository>
<username>@fnancy:~$ cd <repository>
```

### Creating Python Environment

First make sure that Python 3.9 is available:

```shell
<username>@fnancy:~/hector-benchmarking$ python3 --version
Python 3.9.2
```

Create a virtual environment (named `venv`) where we will install Python packages.

```shell
<username>@fnancy:~/hector-benchmarking$ python3 -m venv venv
<username>@fnancy:~/hector-benchmarking$ source venv/bin/activate
```

### Installing Python Packages

Install the following required packages through `pip`:

* enoslib 8.1.2
* hdrhistogram 0.9.2
* numpy 1.23.3
* pandas 1.5.0

```shell
(venv) <username>@fnancy:~/hector-benchmarking$ pip install enoslib==8.1.2 hdrhistogram==0.9.2 numpy==1.23.3 pandas==1.5.0
```

To be able to drive Grid'5000 reservation system from Python, you must also create a file named `.python-grid5000.yaml`
in your home folder and put your credentials:

```shell
(venv) <username>@fnancy:~/hector-benchmarking$ echo '
username: <username>
password: <password>
' > ~/.python-grid5000.yaml

(venv) <username>@fnancy:~/hector-benchmarking$ chmod 600 ~/.python-grid5000.yaml
```

## Getting Started

## Launching Experiments

## Comparing Results
