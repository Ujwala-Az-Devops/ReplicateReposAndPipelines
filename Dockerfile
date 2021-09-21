FROM ubuntu:latest
RUN apt-get -qq update \
  #&& apt-get -qq install -y gcc \
  && apt-get -qq install -y git \
  && apt-get -qq install -y curl \
  && apt-get -qq install -y gpg
 # && apt-get -qq install -y gh
  
WORKDIR mycode
COPY copycode.sh .
COPY ghToken.txt .
RUN chmod 777 /mycode/copycode.sh
RUN chmod 777 /mycode/ghToken.txt
#CMD ["python3", "/mycode/copycode.sh"]
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt-get -qq update
RUN apt-get -qq install gh
