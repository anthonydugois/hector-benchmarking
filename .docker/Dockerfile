FROM python:3

WORKDIR /usr/src/app

COPY . .

RUN apt-get update && \
    apt-get install -y r-base texlive && \
    pip install --no-cache-dir -r requirements.txt && \
    R -e "install.packages('tidyverse')" && \
    R -e "install.packages('tikzDevice')"

CMD [ "./scripts/run.sh", "--help" ]
