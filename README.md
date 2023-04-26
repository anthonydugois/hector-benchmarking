# Hector Benchmarking

This repository contains the scripts and configuration files used to benchmark Hector. We describe here the full
guidelines to reproduce the experiments and compare the results to the paper entitled *Hector: A Framework to Design and
Evaluate Scheduling Strategies in Persistent Key-Value Stores* and submitted to ICPP 2023.

## Getting started

### Installation

The benchmarks are meant to run on the Grid'5000 testbed (https://www.grid5000.fr/w/Grid5000:Home), which is a French
experimental platform. We detail the procedure below to get access to Grid'5000:

1. Request an account here: https://www.grid5000.fr/w/Grid5000:Get_an_account. Follow the provided guidelines, i.e.,
request a regular account if you are an academic in France. Otherwise, request an Open Access account. In any case, if 
you do not already have a Grid'5000 account, it is important to mention in the *Intended usage* form that you plan to
use Grid'5000 to reproduce experiments as part of the Reproducibility Initiative of ICPP.

2. Once your account has been activated, we recommend to read at least the 3 first sections of the Getting Started page
to understand the basics of Grid'5000 architecture: https://www.grid5000.fr/w/Getting_Started.

3. (Optional.) We also strongly recommend to setup SSH aliases as shown in the Getting Started guide (replace `login`
with your username):

    ```
    Host g5k
      User login
      Hostname access.grid5000.fr
      ForwardAgent no
    
    Host *.g5k
      User login
      ProxyCommand ssh g5k -W "$(basename %h .g5k):%p"
      ForwardAgent no
    ```

4. When everything is setup, connect to Nancy's frontend: `ssh nancy.g5k`.

5. To be able to drive Grid'5000 from Python, you must create a file named `.python-grid5000.yaml` in your home folder
and specify your Grid'5000 credentials:

    ```shell
    <username>@fnancy:~$ echo '
    username: <username>
    password: <password>
    ' > ~/.python-grid5000.yaml
    
    <username>@fnancy:~$ chmod 600 ~/.python-grid5000.yaml
    ```

### Hello World

#### Reserve a node

```shell
<username>@fnancy:~$ oarsub -p gros -l host=1,walltime=1 -I
OAR_JOB_ID=4088412
# Interactive mode: waiting...
# Starting...
<username>@gros-20:~$ 
```

**Optional**: use tmux before reserving a node. When reserving and using a node on Grid'5000 (in interactive mode),
being disconnected from the session will terminate the current job. To avoid this, we strongly recommend using tmux.

```shell
<username>@fnancy:~$ tmux new -s my-session
```

In addition, this allows to go back on the frontend without terminating the current job (hit `Ctrl+B D` to return on the
frontend, and execute `tmux a -t my-session` to reattach the current session on the screen). This is useful, for
instance, to increase the walltime of a running job. See https://github.com/tmux/tmux/wiki for more details.

#### Setup Docker

The benchmarking system is available through a Docker image. Setting up Docker on a Grid'5000 node can be done in a
single command:

```shell
<username>@gros-20:~$ g5k-setup-docker -t
```

#### A simple experiment

Let us start with a simple and quick experiment to check that everything is correctly setup.

```shell
<username>@gros-20:~$ mkdir -p hector/log hector/output
```

```shell
<username>@gros-20:~$ docker run -d --rm \
                      --network host \
                      --mount type=bind,source=~/.python-grid5000.yaml,target=/root/.python-grid5000.yaml \
                      --mount type=bind,source=~/hector/log,target=/usr/src/app/log \
                      --mount type=bind,source=~/hector/output,target=/usr/src/app/experiment/output \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/run.sh experiment/input/helloworld.csv --job-name helloworld --start-index 10 --walltime 1:00:00 --log log
```

```shell
<username>@gros-20:~$ tail -f hector/log/helloworld.log
```

#### Post-processing results

```shell
<username>@gros-20:~$ mkdir -p hector/archives
```

```shell
<username>@gros-20:~$ docker run --rm \
                      --mount type=bind,source=~/hector/output,target=/usr/src/app/experiment/output \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/tidy.sh experiment/output/helloworld --archive
```

#### Analyzing and plotting data

```shell
<username>@gros-20:~$ docker run --rm \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/plot.sh plots/helloworld.R experiment/archives/helloworld
```

## Reproduce experiments

### Run experiments

```shell
<username>@gros-20:~$ mkdir -p hector/archives
```

```shell
<username>@gros-20:~$ docker run -d --rm \
                      --network host \
                      --mount type=bind,source=~/.python-grid5000.yaml,target=/root/.python-grid5000.yaml \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/xp1_baseline.sh 10 48:00:00
```

```shell
<username>@gros-20:~$ docker run -d --rm \
                      --network host \
                      --mount type=bind,source=~/.python-grid5000.yaml,target=/root/.python-grid5000.yaml \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/xp2_replica_selection.sh 10 48:00:00
```

```shell
<username>@gros-20:~$ docker run -d --rm \
                      --network host \
                      --mount type=bind,source=~/.python-grid5000.yaml,target=/root/.python-grid5000.yaml \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/xp3_local_scheduling.sh 10 48:00:00
```

### Report results

```shell
<username>@gros-20:~$ mkdir -p hector/report
```

```shell
<username>@gros-20:~$ docker run -d --rm \
                      --network host \
                      --mount type=bind,source=~/hector/archives,target=/usr/src/app/experiment/archives \
                      --mount type=bind,source=~/hector/report,target=/usr/src/app/experiment/report \
                      adugois1/hector-benchmarking:latest \
                      ./scripts/report.sh
```

## Comparing results

TODO
