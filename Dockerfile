FROM python:3.12.1-alpine
RUN pip install sphinx-sizzle-theme
RUN  apk add make
COPY . /opt
WORKDIR /opt
RUN make html

RUN tar -zcf web.tar.gz -C _build/html/ .