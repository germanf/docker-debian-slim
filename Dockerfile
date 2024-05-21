# Usa una imagen base de Debian
FROM debian:stable-slim

# Instala wget, sudo, jq, bash-completion, git, iputils-ping, cat, less, y bc
RUN apt-get update && \
    apt-get install -y wget sudo jq bash-completion git iputils-ping coreutils less procps bc && \
    rm -rf /var/lib/apt/lists/*

# Agrega el usuario satoshi y con permisos de sudo
RUN useradd -ms /bin/bash satoshi && \
    adduser satoshi sudo

# Permite al usuario satoshi ejecutar comandos sudo sin contraseña
RUN echo 'satoshi ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Define el directorio de trabajo
WORKDIR /home/satoshi

# Copia el archivo .bashrc al directorio /home/satoshi
#COPY .bashrc /home/satoshi/.bashrc

# Comandos wget, sudo, jq, git, ping, cat y less
RUN wget --version && sudo --version && jq --version && git --version && ping -V && cat --version && less --version

# Personaliza el prompt de la terminal y habilita el autocompletado
RUN echo "export PS1='🐳 \[\033[1;34m\](satoshi)\[\033[0;35m\] \[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'" >> /home/satoshi/.bashrc && \
    echo "source /etc/profile.d/bash_completion.sh" >> /home/satoshi/.bashrc

# Configuración de colores similar a Fish para Bash
RUN echo "alias ls='ls --color=auto'" >> /home/satoshi/.bashrc && \
    echo "export LS_COLORS='di=1;34:ln=1;36:mh=00:pi=40;33:so=1;35:do=1;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=1;32:*\.tar=1;31:*\.gz=1;31:*\.bz2=1;31:*\.bz=1;31:*\.tgz=1;31:*\.zip=1;31:*\.rpm=1;31:*\.deb=1;31:*\.rar=1;31:*\.ace=1;31:*\.zoo=1;31:*\.cpio=1;31:*\.7z=1;31:*\.jar=1;31:'" >> /home/satoshi/.bashrc

EXPOSE 18443 18444 28334 28335

USER satoshi

# copy ./shared directory to /home/satoshi/shared on container
ADD shared /home/satoshi/shared

# mount /home/satoshi/shared as volume on host
VOLUME /home/satoshi/shared

COPY ./bin/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]
