#!/bin/bash

sincronizar_arquivos() {

    echo "Sincronizing new files and modified ones..."

    # Procura apenas ficheiros na origem / O input introduzido no read sera o output do find e será guardado na variavel arquivo
    find "$ORIGEM" -type f | while read -r arquivo      
    do  
        # Manipula o valor da variavel arquivo para ser o caminho do backup
        backup="$BACKUP/${arquivo#$ORIGEM}"         # Usamos parametros de expansao para trocar o caminho do arquivo pelo caminho do backup

        if [ -e "$backup" ] && [ "$backup" -nt "$arquivo" ]
        then
            echo "WARNING: backup entry $backup is newer than $arquivo; Should not happen"
            AVISOS=$(($AVISOS + 1))
        fi

        # Verifica se o ficheiro existe ou o arquivo é mais recente que o backup
        if [ ! -e "$backup" ] || [ "$arquivo" -nt "$backup" ]       # '-nt' = newer than
        then    
            mkdir -p $(dirname $backup)     # dirname e um comando que estrai o caminho da diretoria do ficheiro destino
            echo "mkdir -p $(dirname $backup)"

            cp -a "$arquivo" "$backup"      # faz a copia do arquivo preservando todos os atributos (-a)  
            echo "cp -a $arquivo $backup"

            # Atualiza o contador e tamanho de ficheiros copiados
            FILE_SIZE=$(stat --format="%s" "$arquivo")  #stat recebe a informação do ficheiro / --format indica o stat para dar como
                                                        #output apenas o tamanho do ficheiro (em bytes)
            if [ ! -e ]

            echo "File $arquivo updated."
        fi
    done
}

remover_arquivos_inexistentes() {

    echo "Removing non-existing files..."

    find "$BACKUP" -type f | while read -r arquivo
    do
        origem="$ORIGEM/${arquivo#BACKUP}"
        
        if [ ! -e "$origem" ]       # Verifica se o arquivo origem existe no arquivo backup
        then                        # Caso não exista, irá eliminá-lo da do backup tambem
            rm "$arquivo"
            echo "File deleted: $arquivo"
        fi
    done

    find "$BACKUP" -type d -empty -delete    
}