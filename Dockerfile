FROM python:3.12.1-alpine as build
RUN pip install sphinx-sizzle-theme
RUN  apk add make
COPY . /opt
WORKDIR /opt
RUN make html

FROM httpd:2.4.58-alpine
COPY --from=build /opt/_build/html /usr/local/apache2/htdocs
