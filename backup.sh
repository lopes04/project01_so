#!/bin/bash

usage() {
    echo "Usage: $0 [-c] [-b tfile] [-r regexpr] <source_directory> <backup_directory>"
    exit 1
}

sincronizar_arquivos() {
    local ORIGEM="$4"
    local BACKUP="$5"

    for item in $ORIGEM/*; do
    
        nome_item=$(basename "$item")
        backup="$BACKUP${item#$ORIGEM}"         

        for exclude in "${excluded_files[@]}"     
        do  
            if [[ "$exclude" == "$nome_item" ]]     
            then
                continue 2                           
            fi
        done


        # Verifica a expressão regular se estiver definida
        if [[ -n "$REGEX" ]] && ! echo "$nome_item" | grep -qE "$REGEX"; then
            continue   
        fi

        if [[ -d "$item" ]]      
        then
            if [[ ! -d $backup ]]
            then                   
                if [[ "$CHECK" == false ]]       
                then
                    mkdir $backup 
                fi
                echo "mkdir ${backup#"$(dirname $BACKUPOG)/"}"
            fi

            sincronizar_arquivos "$CHECK" "$EXCLUDE_LIST" "$REGEX" "$item" "$backup"

        elif [[ -f "$item" ]]
        then
            if [ ! -e "$backup" ] || [ "$item" -nt "$backup" ]       # '-nt' = newer than
            then 
                if [[ "$CHECK" == false ]]
                then
                    cp -a "$item" "$backup"      # Faz a copia do item preservando todos os atributos (-a)  
                fi
                echo "cp -a ${item#"$(dirname $ORIGEMOG)/"} ${backup#"$(dirname $BACKUPOG)/"}"
            fi   
        fi
    done
}

remover_arquivos_inexistentes() {

    local ORIGEM="$2"
    local BACKUP="$3"

    # Procura arquivos no diretório de backup
    for item in "$BACKUP"/*
    do
    
        if [[ "$item" == "$BACKUP" ]]
        then
            continue
        fi 

        # Manipula o valor da variável arquivo para ser o caminho correspondente na origem
        origem="$ORIGEM/${item#$BACKUP/}"

        if [[ -d "$item" ]]
        then
            if [[ ! -d "$origem" ]]
            then
                if [[ "$CHECK" == false ]]
                then
                    rm -rf "$item"
                fi
                echo "rm -rf ${item#"$(dirname $BACKUPOG)/"}"
                continue
            fi

            remover_arquivos_inexistentes "$CHECK" "$origem" "$item"
        elif [[ -f "$item" ]]
        then
            if [[ ! -f "$origem" ]]
            then
                if [[ "$CHECK" == false ]]
                then
                    rm "$item"
                fi
                echo "rm ${item#"$(dirname $BACKUPOG)/"}"
            fi
        fi
    done
}




CHECK=false                             # Check vai ser o valor booleano que indica se o utilizador pretende fazer "checking" do backup
EXCLUDE_LIST=""
REGEX=""
excluded_files=()                       # inicializa a lista de ficheiros a excluir
                                        # : atrás é uma convenção usada para lidar com erros em bash de forma efetiva
                                        # todos os comandos seguido de um : indica que recebe argumentos
while getopts ":cb:r:" opt              # getopts é uma utilidade built in que simplifica parsing flags
do
    case "$opt" in
        c) CHECK=true ;;
        b) EXCLUDE_LIST="$OPTARG" ;;        # "$OPTARG" é uma variável especial que recebe o argumento da opção atual
        r) REGEX="$OPTARG" ;;       # validar o regex depois de capturar o arg da opção -r
        *) usage ;;                      
    esac
done
                                        # OPTIND é uma variavel especial que aponta para o proximo argumento depois da ultima opcao
shift $((OPTIND - 1))                   # subtraimos 1 a OPTIND porque, sabemos que OPTIND aponta para o primeiro argumento obrigatorio
                                        # e nós queremos dar shift até ele e não passar por ele

if [ $# -ne 2 ]; then
    usage
fi

ORIGEMOG="$1"
BACKUPOG="$2"

# Verifica se a origem não é uma diretoria e consequencialmente se não existe
if [ ! -d "$ORIGEMOG" ]
then
    echo "$1 is not a directory"
    exit 1
fi

# Verifica se o backup não é uma diretoria e consequencialmente se não existe
if [ ! -d "$BACKUPOG" ]
then
    if [[ "$CHECK" == false ]]
    then
        mkdir -p "$BACKUPOG"      # Cria a diretoria. Caso as diretorias 'acima' não existam, estas serão criadas também
    fi
    echo "mkdir ${BACKUPOG#"$(dirname $BACKUPOG)/"}"
fi

# Verifica as permissões (escrita no backup e leitura na origem)
if ([ ! -w "$BACKUPOG" ] || [ ! -r "$ORIGEMOG" ]) && [[ $CHECK == false ]]
then
    echo "Check the writing permissions on the backup directory or the reading permissions from the source"
    exit 2
fi

if [[ -n "$EXCLUDE_LIST" ]]         # se a lista foi não está vazia (ou seja, foi passada como argumento)
then
    while IFS= read -r line || [[ -n "$line" ]];
    do  
        line=$(echo "$line" | xargs)
        excluded_files+=("$line")
    done < "$EXCLUDE_LIST"
fi

sincronizar_arquivos "$CHECK" "$EXCLUDE_LIST" "$REGEX" "$ORIGEMOG" "$BACKUPOG"
if [[ -e "$BACKUPOG" ]]
then
    remover_arquivos_inexistentes "$CHECK" "$ORIGEMOG" "$BACKUPOG"
fi

