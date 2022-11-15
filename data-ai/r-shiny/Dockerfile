FROM rocker/shiny-verse:latest 

RUN apt-get update && apt-get install -y \ 
    sudo \ 
    pandoc \ 
    pandoc-citeproc \ 
    libcurl4-gnutls-dev \ 
    libcairo2-dev \ 
    libxt-dev \ 
    libssl-dev \ 
    libssh2-1-dev 

RUN R -e "install.packages(c('shinydashboard','shiny', 'plotly', 'dplyr', 'magrittr', 'RPostgreSQL', 'DT', 'rjson', 'pool'))" 
RUN R -e "install.packages('gpclib', type='source')" 
RUN R -e "install.packages('rgeos', type='source')" 
RUN R -e "install.packages('rgdal', type='source')" 

COPY ./App /srv/shiny-server/App 

EXPOSE 3838 

RUN sudo chown -R shiny:shiny /srv/shiny-server 

CMD ["/usr/bin/shiny-server.sh"]