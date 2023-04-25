# Hector Benchmarking

This repository contains the scripts and configuration files used to benchmark Hector. We describe here the full
guidelines to reproduce the experiments and compare the results to the paper entitled *Hector: A Framework to Design and
Evaluate Scheduling Strategies in Persistent Key-Value Stores* and submitted to ICPP 2023.

## Getting Started

### Setup Grid'5000 Account

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

### Reserving a Node

```shell
<username>@fnancy:~$ oarsub -p gros -l host=1,walltime=1 -I
OAR_JOB_ID=4088412
# Interactive mode: waiting...
# Starting...
<username>@gros-20:~$ 
```

### Setup Docker

```shell
<username>@gros-20:~$ g5k-setup-docker -t
```

```shell
<username>@gros-20:~$ docker run --rm adugois1/hector-benchmarking:latest
```

## Launching Experiments

## Comparing Results
