FROM python:3

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync r-base texlive && \
    R -e "install.packages('tidyverse')" && \
    R -e "install.packages('tikzDevice')"

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . ./

RUN chmod +x scripts/*

#RUN mkdir /root/.ssh && \
#    echo "Host *" >> /root/.ssh/config && \
#    echo "  StrictHostKeyChecking no" >> /root/.ssh/config && \
#    echo "  HashKnownHosts no" >> /root/.ssh/config

CMD [ "./scripts/run.sh", "--help" ]
