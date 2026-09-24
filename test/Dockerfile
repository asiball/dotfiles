# クリーンな Ubuntu で install.sh / setup.sh を試すためのコンテナ(test/run.sh が使う)
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y sudo curl ca-certificates \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && printf '[safe]\n\tdirectory = /src/.git\n' > /etc/gitconfig   # ホストと uid が違っても /src から clone できるように
USER ubuntu
WORKDIR /home/ubuntu
