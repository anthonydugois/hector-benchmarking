FROM python:3

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get install -y r-base texlive && \
    pip install --no-cache-dir -r requirements.txt && \
    R -e "install.packages('tidyverse')" && \
    R -e "install.packages('tikzDevice')"

COPY . .

RUN chmod 777 scripts/*

RUN mkdir /root/.ssh && \
    echo "Host *" >> /root/.ssh/config && \
    echo "  StrictHostKeyChecking no" >> /root/.ssh/config && \
    echo "  HashKnownHosts no" >> /root/.ssh/config

CMD [ "./scripts/run.sh", "--help" ]
