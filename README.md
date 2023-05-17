# Hector Benchmarking

This repository contains the scripts and configuration files used to benchmark Hector. We describe here the full
guidelines to reproduce the experiments and compare the results to the paper entitled *Hector: A Framework to Design and
Evaluate Scheduling Strategies in Persistent Key-Value Stores* and submitted to ICPP 2023.

## Getting started

### Installation

The benchmarks are meant to run on the Grid'5000 testbed (https://www.grid5000.fr/w/Grid5000:Home), which is a French
experimental platform. We detail the procedure below to get access to Grid'5000:

1. Request an account here: https://www.grid5000.fr/w/Grid5000:Get_an_account. Follow the provided guidelines, i.e.,
request a free Open Access account, mentioning in the *Intended usage* form that you plan to use Grid'5000 to reproduce
experiments as part of the Reproducibility Initiative of ICPP.

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
    user@fnancy:~$ echo '
    username: <username>
    password: <password>
    ' > ~/.python-grid5000.yaml
    
    user@fnancy:~$ chmod 600 ~/.python-grid5000.yaml
    ```

### Hello World

#### Reserve a node

When reserving and using a node on Grid'5000 (in interactive mode), being disconnected from the session will terminate
the current job. To avoid this, we strongly recommend using tmux.

```shell
user@fnancy:~$ tmux new -s my-session
```

In addition, this allows to go back on the frontend without terminating the current job (hit `Ctrl+B D` to return on the
frontend, and execute `tmux a -t my-session` to reattach the current session on the screen). This is useful, for
instance, to increase the walltime of a running job. See https://github.com/tmux/tmux/wiki for more details.

```shell
user@fnancy:~$ oarsub -p gros -l host=1,walltime=1 -I
OAR_JOB_ID=4088412
# Interactive mode: waiting...
# Starting...
user@gros-20:~$ 
```

#### Setup Docker

The benchmarking system is available through a Docker image. Setting up Docker on a Grid'5000 node can be done in a
single command:

```shell
user@gros-20:~$ g5k-setup-docker -t
```

#### A simple experiment

Let us start with a simple and quick experiment to check that everything is correctly setup. First, we create
`hector/log` and `hector/archives` folders to save some data from the Docker filesystem. `hector/log` will contain the
experiment log files, which are useful to follow the process while it is running, and `hector/archives` will contain the
gzipped results of the experiment.

```shell
user@gros-20:~$ mkdir -p hector/log hector/archives
```

Now we run the experiment (estimated duration: 60 minutes). This is done through a Docker container that handles all the
dependencies and installation process. However, the container must be able to communicate with the remote nodes. It
needs, for instance, to have access to our SSH keys. We also give him access to the SSL certificate and the
`.python-grid5000.yaml` file.

```shell
user@gros-20:~$ docker run --detach --network host \
                -v ~/.ssh/id_rsa:/root/.ssh/id_rsa:ro \
                -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub:ro \
                -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
                -v ~/.python-grid5000.yaml:/root/.python-grid5000.yaml:ro \
                -v ~/hector/log:/usr/src/app/log:rw \
                -v ~/hector/archives:/usr/src/app/archives:rw \
                adugois1/hector-benchmarking:latest \
                sh scripts/helloworld.sh nancy gros 21 1:00:00
```

**Tip.** For more convenience, we can make a custom shell script `start.sh` to avoid crafting a complex Docker command
each time we need to launch an experiment. This will be useful in the next section.

```shell
#!/bin/sh

mkdir -p hector/log hector/archives

docker run --detach --network host \
   -v ~/.ssh/id_rsa:/root/.ssh/id_rsa:ro \
   -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub:ro \
   -v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro \
   -v ~/.python-grid5000.yaml:/root/.python-grid5000.yaml:ro \
   -v ~/hector/log:/usr/src/app/log:rw \
   -v ~/hector/archives:/usr/src/app/archives:rw \
   adugois1/hector-benchmarking:latest sh "$@"
```

Do not forget to make it executable (`chmod +x start.sh`). Then we can use it like that:

```shell
user@gros-20:~$ ./start.sh scripts/helloworld.sh nancy gros 21 1:00:00
```

We can track the progress of the experiment by looking at the logs, which update in real time through the network thanks
to the shared filesystem of Grid'5000. If you used tmux, hit `Ctrl+B D` to go back on the frontend node, and watch the
logs from there.

```shell
user@fnancy:~$ tail -f ~/hector/log/helloworld.log
```

At the end of the experiment, another process begins to transform the raw results in a format that is more suitable for
the analysis. When this second process terminates, we get two gzipped tar files in `hector/archives`: one that contains
raw results, and another one that contains summarized results. These summarized results are ready to be analyzed, and
these are the ones that are used to make our final figures.

## Reproduce experiments

### Run experiments

Let us reuse our `start.sh` script.

**Experiment 1.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-20:~$ ./start.sh scripts/xp1_baseline.sh nancy gros 21 48:00:00
```

**Experiment 2.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-20:~$ ./start.sh scripts/xp2_replica_selection.sh nancy gros 21 48:00:00
```

**Experiment 3.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-20:~$ ./start.sh scripts/xp3_local_scheduling.sh nancy gros 21 48:00:00
```

### Report results

```shell
user@gros-20:~$ mkdir -p hector/report
```

```shell
user@gros-20:~$ docker run \
                -v ~/hector/archives:/usr/src/app/archives \
                -v ~/hector/report:/usr/src/app/report \
                adugois1/hector-benchmarking:latest sh scripts/report.sh
```

Downloading the report file on the local machine can be done through `scp`:

```shell
user@local:~$ scp user@nancy.g5k:~/hector/report/report.pdf ~/report.pdf
```

### Quick report

```shell
user@gros-20:~$ mkdir -p hector/report
```

```shell
user@gros-20:~$ docker run \
                -v ~/hector/report:/usr/src/app/report \
                adugois1/hector-benchmarking:latest sh scripts/quick_report.sh
```

```shell
user@local:~$ scp user@nancy.g5k:~/hector/report/quick_report.pdf ~/quick_report.pdf
```

## Compare results

The report is a PDF file that should summarize the results shown in the paper: Figures 4, 5, 6, 7, 8, 9 and 10, and
Tables 1, 2 and 3. For each figure and table, we describe below the main results that should be reproduced.

**Figure 4.**
This figure shows the maximum attainable throughput for Apache Cassandra and Hector. We want to show that both systems
achieve similar results in the nominal case. Therefore, the two columns should represent similar values, and the error
bars should indicate that the (small) difference between the two columns is not significant.

**Figure 5.**
This figure shows the latency for Apache Cassandra and Hector with two arrival rates. It is complementary to Figure 4,
i.e., we want to make sure that both systems behave similarly. Thus, in each facet, the two columns should represent
similar values, and the error bars should indicate that the (small) difference between the two columns is not
significant.

**Figure 6.**
This figure shows the maximum attainable throughput for 3 different scheduling algorithms (DS, C3 and PA) under two
key popularity distributions. In the left facet, the curves should be different, with DS being always lower than PA.
Ideally, C3 should progressively increase over time. In the right facet, all curves should be more or less similar.

**Figure 7.**
This figure shows the volume of data that is read over time for DS, C3 and PA under two key popularity distributions.
It is complementary to Figure 6: PA should be always lower than DS, and C3 should ideally decrease over time.

**Figure 8.**
This figure shows the attainable throughput of 2 different scheduling algorithms (FCFS and RML) as a function of the
arrival rate. FCFS should saturate faster than RML, i.e., the columns should be capped earlier.

**Figure 9.**
This figure shows the latency of FCFS and RML as a function of the arrival rate. It is complementary to Figure 8. In
each facet, RML should show lower latencies than FCFS, possibly with some exceptions for high arrival rates
(>= 50 kops/s). However, the median latencies (top-right facet) should be very low compared to FCFS, for all shown
arrival rates.

**Figure 10.**
This figure shows the latency of small and large requests for different arrival rates. It is complementary to Figure 9.
For the first arrival rate value, FCFS and RML should show similar results. When RML reaches its saturating throughput
(see Figure 8), the latency of small requests in RML should be lower than the latency of small requests in FCFS.

**Table 1.**
This table is complementary to Figure 4 and shows absolute throughputs, as well as differences between both systems. The
differences should be small, i.e., the relative difference should be around 1%.

**Table 2.**
This table is complementary to Figure 5 and shows absolute latencies, as well as differences between both systems. The
differences should be small, i.e., the relative difference should be around 1%.

**Table 3.**
This table is complementary to Figure 6 and summarizes the distribution of throughput values that have been recorded
over time. We should simply see values that are consistent with Figure 6.
