# Hector Benchmarking

This repository contains the scripts and configuration files used to benchmark Hector. We describe here the full
guidelines to reproduce the experiments and compare the results to the paper entitled *Hector: A Framework to Design and
Evaluate Scheduling Strategies in Persistent Key-Value Stores* and submitted to ICPP 2023.

## Getting started

### Installation

The benchmarks are meant to run on the Grid'5000 testbed (https://www.grid5000.fr/w/Grid5000:Home), which is a French
experimental platform. Unfortunately, the benchmarking software **cannot** be run on a different platform, as the
deployment process is tied to the Grid'5000 API. We detail the procedure below to get access to Grid'5000:

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

Let's begin with a dummy benchmark to check that everything is working as expected.

#### Reserve a node

When reserving and using a node on Grid'5000 (in interactive mode), being disconnected from the session will terminate
the current job. To avoid this, we strongly recommend using tmux.

```shell
user@fnancy:~$ tmux new -s my-session
```

In addition, once connected to a node, this allows to go back on the frontend without terminating the current job, which
would also release the node (hit `Ctrl+B D` to return on the frontend, and execute `tmux a -t my-session` from the
frontend to reattach the current session on the screen and go back on the reserved node). This is useful, for instance,
to increase the walltime of a running job. See https://github.com/tmux/tmux/wiki for more details.

Let's reserve and connect to a node in the cluster named `gros` (from Nancy's site) for 1 hour:

```shell
user@fnancy:~$ oarsub -p gros -l host=1,walltime=1 -I
OAR_JOB_ID=4088412
# Interactive mode: waiting...
# Starting...
user@gros-20:~$ 
```

In this example, the reservation system of Grid'5000 gave us access to the node 20.

#### Setup Docker

Our benchmarking system is available through a Docker image. Setting up Docker on a Grid'5000 node can be done in a
single command:

```shell
user@gros-20:~$ g5k-setup-docker -t
```

#### A simple experiment

Let's start with a simple and quick experiment. First, we create `hector/log` and `hector/archives` folders to save some
data from the Docker filesystem. `hector/log` will contain the experiment log files, which are useful to follow the
benchmarking process while it is running, and `hector/archives` will contain the gzipped results of the experiment.

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

Notice the last line `sh scripts/helloworld.sh nancy gros 21 1:00:00`. This is the script that starts the actual
benchmarking process. All benchmarking scripts of this document take exactly 4 parameters:

* the Grid'5000 site (in this example, this is `nancy`),
* the cluster in which we want to reserve nodes (in this example, this is `gros`),
* the starting index of the nodes we want to reserve (in this example, this is the node `21`, which means that we
use the 5 nodes 20, 21, 22, 23, and 24: 1 driver node and 4 experiment nodes, among which 1 benchmarking node and 3
nodes for the system itself),
* the expected walltime of the experiment, in format `hh:mm:ss` (in this example, this is 1 hour).

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

Once it has started, we can track the progress of the experiment by looking at the logs, which update in real time 
through the network thanks to the shared filesystem of Grid'5000. If you used tmux, hit `Ctrl+B D` to go back on the 
frontend node, and watch the logs from there.

```shell
user@fnancy:~$ tail -f ~/hector/log/helloworld.log
```

At the end of the experiment, another process automatically begins to transform the raw results in a format that is more
suitable for the analysis. When this second process terminates, we get two gzipped tar files in `hector/archives`: one
that contains raw results, and another one that contains summarized results. These summarized results are ready to be 
analyzed, and these are the ones that are used to make our final figures.

## Reproduce experiments

> **Disclaimer: make sure to read the full section before launching any experiment.**

We are now ready to launch the actual experiments. Let us reuse our `start.sh` script.

**Experiment 1.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-70:~$ ./start.sh scripts/xp1_baseline.sh nancy gros 10 48:00:00
```

**Experiment 2.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-71:~$ ./start.sh scripts/xp2_replica_selection.sh nancy gros 30 48:00:00
```

**Experiment 3.** Requirements:

* Estimated duration: 48 hours
* Number of nodes: 20

```shell
user@gros-72:~$ ./start.sh scripts/xp3_local_scheduling.sh nancy gros 50 48:00:00
```

**Making advanced reservation.** As these experiments take a long time to run, we strongly recommend to perform them on
the weekend, as the Grid'5000 platform does not allow to run long jobs during weekdays from 9AM to 7PM. Thus, one may
reserve nodes in advance to ensure that launching the 3 experiments will be possible. As each experiment needs 20 nodes
and 1 driver node, this makes 63 nodes in total to reserve for 48 hours. Recall that the reserved nodes must constitute
a contiguous range within a single experiment.

Let us reserve 63 nodes on the gros cluster of Nancy datacenter (do not forget to adapt the reservation date
accordingly):

```shell
user@fnancy:~$ oarsub -p "host LIKE 'gros-1_.%' OR \
                          host LIKE 'gros-2_.%' OR \
                          host LIKE 'gros-3_.%' OR \
                          host LIKE 'gros-4_.%' OR \
                          host LIKE 'gros-5_.%' OR \
                          host LIKE 'gros-6_.%' OR \
                          host LIKE 'gros-70.%' OR \
                          host LIKE 'gros-71.%' OR \
                          host LIKE 'gros-72.%'" -l host=63,walltime=48:00:00 -r '2023-06-16 19:00:00'
```

Hosts `gros_1*` and `gros_2*` will be used for the experiment 1, with the host `gros_70` as the driver node.
Hosts `gros_3*` and `gros_4*` will be used for the experiment 2, with the host `gros_71` as the driver node.
Hosts `gros_5*` and `gros_6*` will be used for the experiment 3, with the host `gros_72` as the driver node.

Note that the experiments will not start automatically. At this point, we only made sure that the nodes are reserved and
won't be used by other people.

Grid'5000 allows one to launch long jobs sooner than 7PM if the nodes are still free starting from 5PM. Thus, at 
**Friday 5PM**, one may delete the previous reservation and manually launch the 3 experiments above:

```shell
user@fnancy:~$ oardel 4088412 # replace with the actual JOB_ID of the previous reservation
```

**Tip:** if you lost the `JOB_ID`, execute `oarstat -u` to see the list of your reserved/running jobs.

To summarize, here is the full command suite to launch the first experiment (after having deleted the reservation):

```shell
user@fnancy:~$ tmux new -s xp1
user@fnancy:~$ oarsub -p gros-70 -l host=1,walltime=48:00:00 -I
# ...
user@gros-70:~$ g5k-setup-docker -t
user@gros-70:~$ mkdir -p hector/log hector/archives
user@gros-70:~$ ./start.sh scripts/xp1_baseline.sh nancy gros 10 48:00:00
```

1. We start a new tmux session.
2. We connect to a driver node. In this example, we launch the experiment 1, and we planned to use the node 70 to driver 
this experiment. Moreover, we reserve this node for 48 hours (the expected duration of the experiment).
3. We setup Docker on the driver node.
4. We create the two needed folders.
5. We actually start the experiment on cluster `gros` of Nancy's site, on nodes 10 to 29 (as the experiment needs 20 
nodes), for 48 hours.

Then hit `Ctrl+B D` to go back to frontend and launch experiments 2 and 3 in parallel.

### Shorter experiments

We provide shorter versions of the experiments for convenience. Note that these versions still take several hours to 
execute, although they should necessitate at most 10 hours, which means that one may launch them during the week (either
during the day between 9AM and 19PM, or during the night between 19PM and 9AM).

**Experiment 1.** Requirements:

* Estimated duration: 10 hours
* Number of nodes: 20

```shell
user@gros-70:~$ ./start.sh scripts/xp1_baseline__short.sh nancy gros 10 10:00:00
```

**Experiment 2.** Requirements:

* Estimated duration: 10 hours
* Number of nodes: 20

```shell
user@gros-71:~$ ./start.sh scripts/xp2_replica_selection__short.sh nancy gros 30 10:00:00
```

**Experiment 3.** Requirements:

* Estimated duration: 10 hours
* Number of nodes: 20

```shell
user@gros-72:~$ ./start.sh scripts/xp3_local_scheduling__short.sh nancy gros 50 10:00:00
```

**Warning:** the results of these shorter versions may differ from the expected results described at the end of this
document. However, the main takeaways should still be visible.

### Report results

Once archives have been obtained in `~/hector/archives`, we are ready to generate the PDF report that contains all
figures and tables. Reserve any node, setup Docker, and build the report:

```shell
user@gros-99:~$ mkdir -p hector/report && \
                docker run \
                -v ~/hector/archives:/usr/src/app/archives \
                -v ~/hector/report:/usr/src/app/report \
                adugois1/hector-benchmarking:latest sh scripts/report.sh
```

Finally, downloading the report file on the local machine can be done, for instance, through `scp`:

```shell
user@local:~$ scp user@nancy.g5k:~/hector/report/report.pdf ~/report.pdf
```

### Quick report

For convenience, we include the data we used to build the figures in the article. One may reproduce the exact same
figures **without launching any experiment** by quickly generating a report based on these data:

```shell
user@gros-99:~$ mkdir -p hector/report && \
                docker run \
                -v ~/hector/report:/usr/src/app/report:rw \
                adugois1/hector-benchmarking:latest sh scripts/quick_report.sh
```

Then download the report on the local machine:

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
