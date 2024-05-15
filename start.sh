#!/bin/bash

clear 
#set -x

# Función para mostrar spinner
show_loading() {
local pid=$1
    local timeout=$2
    local delay=0.15
    local spin='-\|/'
    local start_time=$(date +%s)

    echo -ne "Iniciando el contenedor "
    local spin_index=0
    while [ "$(docker ps -qf "name=debian-slim-instance")" == "" ]; do
        printf "[%c] " "${spin:spin_index:1}"  # Access single character from spin using index
        spin_index=$(( (spin_index + 1) % ${#spin} ))  # Update index for next character

        local current_time=$(date +%s)
        local time_diff=$((current_time - start_time))
        if [ "$time_diff" -ge "$timeout" ]; then
        echo -e "\nTimeout alcanzado. No se pudo iniciar el contenedor a tiempo."
        exit 1
        fi
        sleep $delay
        echo -ne "\b\b\b\b"
    done
echo -ne "\b\b\b\b"
echo "Contenedor iniciado."
}

# Función para preguntar al usuario
ask_user() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor, responde con y o n.";;
        esac
    done
}

# Verifica si ya existe una instancia del contenedor y la elimina si es necesario
if docker ps -aqf "name=debian-slim-instance" | grep -q .; then
    echo "El contenedor debian-slim-instance ya existe."
    if ask_user "¿Desea eliminar la instancia de contenedor existente?"; then
        echo "Eliminando la instancia de contenedor existente..."
        docker rm -f debian-slim-instance
        echo "La instancia de contenedor existente ha sido eliminada."
    else
        echo "No se eliminará la instancia de contenedor existente."
    fi
fi

# Verifica si la imagen ya existe
if docker inspect debian-slim &>/dev/null; then
    echo "La imagen 'debian-slim' ya existe."

    # Pregunta al usuario si desea eliminar la imagen existente
    if ask_user "¿Desea eliminar la imagen existente?"; then
        echo "Eliminando la imagen existente..."
        # Se agrega el flag --force para forzar la eliminación de la imagen
        docker rmi debian-slim --force
        echo "La imagen existente ha sido eliminada."
    else
        echo "No se eliminará la imagen existente. Continuando con la ejecución del script."
    fi
fi

# Verifica si el directorio home existe
if [ ! -d "./shared" ]; then
    echo "El directorio './shared' no existe, creándolo..."
    mkdir ./shared
fi

# Construye el contenedor
echo $(pwd)
echo "===================="

# --no-cache: usar solo si hay inconvenientes con el modo por default
#docker build --no-cache -t debian-slim -f $(pwd)/Dockerfile .
docker build -t debian-slim -f $(pwd)/Dockerfile .

# Verifica si la construcción fue exitosa
if [ $? -eq 0 ]; then
    echo "El contenedor se ha construido exitosamente."

    # Espera 3 segundos antes de iniciar el contenedor
    echo "Iniciando el contenedor..."
    # No se necesita sleep aquí, ya que show_loading se encargará de esperar.

    # Verifica si ya existe una instancia del contenedor y la elimina si es necesario
    if docker ps -aqf "name=debian-slim-instance" | grep -q .; then
        docker rm -f debian-slim-instance
    fi

    # Inicia el contenedor en segundo plano
    # -v/--volume {LOCAL_DIR:CONTAINER_DIR}: Monta un volumen del host en el contenedor
    #   alert! Si hay un comando ADD en el archivo Dockfile y apuntan al mismo directorio será sobreescrito
    # -it: Esto mantiene la entrada estándar (stdin) abierta y asigna un pseudo-TTY (terminal) para el contenedor. 
    #   Esto le permite interactuar con el shell del contenedor.
    #docker run -d -v $(pwd)/shared:/home/satoshi/shared -e "DOCKER_OPTS=--log-level=debug" --name debian-instance-slim debian-slim:latest
    docker run -d -it -v $(pwd)/shared:/home/satoshi/shared -e "DOCKER_OPTS=--log-level=debug" --name debian-slim-instance debian-slim:latest
    #docker run -d -it -e "DOCKER_OPTS=--log-level=debug" --name debian-slim-instance debian-slim:latest

    # Muestra una barra de carga hasta que el contenedor se inicie completamente
    show_loading "$$" 10  # Aquí se establece un timeout de 10 segundos

    # Obtiene el ID del contenedor en ejecución
    CONTAINER_ID=$(docker ps -qf "name=debian-slim-instance")

    # Verifica si el contenedor se ha iniciado correctamente
    if [ -z "$CONTAINER_ID" ]; then
        echo "Error: no se pudo iniciar el contenedor."
    else
        echo "El contenedor se ha iniciado correctamente con ID: $CONTAINER_ID."
        # Devuelve una shell al contenedor en ejecución
        docker exec -it -u satoshi "${CONTAINER_ID}" /bin/bash
    fi
else
    echo "Se encontraron errores durante la construcción del contenedor."
fi
