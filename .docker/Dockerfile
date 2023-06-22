FROM python:3

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync r-base texlive latexmk && \
    R -e "install.packages('tidyverse')" && \
    R -e "install.packages('tikzDevice')" && \
    R -e "install.packages('xtable')"

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . ./

RUN chmod +x scripts/*

CMD [ "./scripts/run.sh", "--help" ]
