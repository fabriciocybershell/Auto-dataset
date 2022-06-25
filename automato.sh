#! /bin/bash

[[ "${7}" ]] || echo "analisando informações e verificando dependências, aguarde até terminar ..."

programs=(  sox spleeter ffmpeg jq  yt-dlp )
for verificar in ${programs[@]};do
	command -v ${verificar} 1>&- || {
		echo -e "programa ${verificar} não instalado\nrealizando instalação automática ..."
		[[ ${verificar} =~ (sox|jq|ffmpeg) ]] && apt install ${verificar}
		[[ ${verificar} =~ (spleeter|yt-dlp) ]] && pip install ${verificar}
	}
done

[[ -a thread ]] || mkfifo thread

baixar(){
	#coletar ID
	[[ "${F1}" =~ /(watch|playlist|youtu\.be)(\?(v|list)=|\/)([a-zA-Z0-9_-]+) ]]
	ID="${BASH_REMATCH[4]}"
	TIPO="${BASH_REMATCH[1]}"

#  [[ "${TIPO}" = "watch" ]] && echo "https://www.youtube.com/watch?v=${ID}"
#  [[ "${TIPO}" = "playlist" ]] && echo "https://www.youtube.com/playlist?list=${ID}"

	[[ "${TIPO}" =~ (watch|youtu\.be) ]] && {
		#midia=$(youtube-dl --get-url "https://www.youtube.com/watch?v=${ID}")
		#while read linha;do
		#	link="${linha}"
		#done <<< "${midia}"

		yt-dlp "https://www.youtube.com/watch?v=${ID}"

		#wget "${link}" -O "audio_${contagem}.mp3"
	}

	[[ "${TIPO}" = "playlist" ]] && {
		echo "playlist detectada, realizando varreduras ...\n"

		contagem=1
		while read linha;do
			[[ "${linha}" =~ /watch\?v=([a-zA-Z0-9_-]+) ]] && {
				[[ "${videos[@]}" = *"${BASH_REMATCH[1]}"* ]] || {
					printf "https://www.youtube.com/watch?v=${BASH_REMATCH[1]}&list=${ID}&index=${contagem}\n"
					videos[${contagem}]="https://www.youtube.com/watch?v=${BASH_REMATCH[1]}&list=${ID}&index=${contagem}"
					contagem=$((contagem+1))
				}
			}
		done < <(wget -qO- "https://youtube.com/playlist?list=${ID}" | tr ',' '\n')

		multi_thread=${#videos[@]}
		echo "total threads: ${multi_thread}"

		echo "modo: HIPERBOOST! 1"

		contagem=0
		for video in ${videos[@]};do 
			(
#			midia=$(youtube-dl --get-url "${video}")
#			while read linha;do
#				link="${linha}"
#			done <<< "${midia}"

			yt-dlp "${video}"
#			wget "${link}" -O "audio_${contagem}.mp3"
			#contagem=$((contagem+1))
		
			#sinalizador:
			echo 'a' > thread
			)&
			contagem=$((contagem+1))
		done

		#monitorando threads:
		unset contagem
		while :
		do
			soma=$(wc -l <<< "$(< thread)")
			contagem=$((contagem+soma))
			echo "${contagem}/${multi_thread} audios terminados ..."
			[[ "$contagem" = "${multi_thread}" ]] && break
		done
	}

	[[ "${F1}" =~ drive.*sharing ]] && {
		yt-dlp "${F1}"
		#youtube-dl "${F1}"
	}
}

get_title(){
  [[ $(curl -s "${F1}" -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36' --compressed) =~ \<title\>(.*)\<\/title\> ]] && {
    busca=${BASH_REMATCH[1]% \|*}
    busca=${busca%-*}
  }
}

spider(){
  salvar=$(wget --spider "${F1}")
  [[ "${salvar}" =~ (l|L)oca(te|lização):\ ([^\ ]*) ]] && link=${BASH_REMATCH[3]}
  [[ "${F1}" = "deezer" ]] && link=${link/\/track/\/br\/track\/}
}

[[ ${5} -eq 1 ]] && {
	[[ ${1} ]] && {
		IFS=',' read F1 F2 <<< "${1// /}"
		while :
		do
			#verificar variavel, se vazia, pular
			[[ ${F1} ]] && {
				#fazer o download do primeiro link, depois, repassar para a primeira variavel
			    echo "analyzing 🔎 ..."

			    [[ ${F1} =~ (youtu|drive) ]] && {
				    echo -e "\ndownloading ⬇️:${F1}, please wait ...\n"
			        baixar
					}
					[[ ${F1} = *"youtu"* ]] || {
				      get_title
				      [[ ${busca} && ${busca} =~ (youtub?e?|tidal|soundcloud|deezer|spotfy|apple) ]] && {
				        spider
				        get_title "${F1}"
				      }

				      [[ "$(curl -si "https://www.youtube.com/results?search_query=${busca// /\+}")" =~ /watch\?v=([a-zA-Z0-9_-]+) ]] && {
				        F1=${BASH_REMATCH[1]}
				        baixar
				        echo "downloading ⬇️ ..."
				      }
				  }

				unset F1
				IFS=',' read F1 F2 <<< "${F2}"
			} || break
		done
		estavel=1
		#botar threads aqui -----------------------------------------------------------
	}

	[[ ${2} && ${3} && ${4} -ge 1 ]] && {
		[[ "${2,,}" =~ (seriado|1) ]] && busca="cenas iconicas compilado ${3}"
		[[ "${2,,}" =~ (filme|2) ]] && busca="cenas frases trainler compilado ${3}"
		[[ "${2,,}" =~ (desenho|seriado|4) ]] && busca="episodios mensagens cenas ${3}"
		[[ "${2,,}" =~ (youtuber|3) ]] && busca="${3}"
		[[ "${2,,}" =~ (documentario|5) ]] && busca="episodio discover temporada ${3}"

		[[ ${busca} ]] && {
			contagem=0
			echo "vídeos a baixar:"
			while read linha;do
				[[ "${linha}" =~ /watch\?v=([a-zA-Z0-9_-]+) ]] && {
					[[ ${4} -eq ${contagem} ]] && break
					printf "https://www.youtube.com%s\n" ${BASH_REMATCH[0]}
					videos[${contagem}]="https://www.youtube.com${BASH_REMATCH[0]}"
					contagem=$((contagem+1))
				}
			done < <(wget -qO- "https://www.youtube.com/results?search_query=${busca// /\+}" | tr ',' '\n')

			echo -e "\n${#videos[@]} vídeos no total ..."

			multi_thread=${#videos[@]}
			echo "total threads: ${multi_thread}"

			echo "modo: HIPERBOOST! 2"

			contagem=0

			for down in ${videos[@]};do
				(
					yt-dlp "${down}"
					echo 'a' > thread
				)&
				contagem=$((contagem+1))
			done

					#monitorando threads:
			unset contagem
			while :
			do
				soma=$(wc -l <<< "$(< thread)")
				contagem=$((contagem+soma))
				echo "${contagem}/${multi_thread} downloads terminados ..."
				[[ "$contagem" = "${multi_thread}" ]] && break
			done
			estavel=1
		}
	}

	#verificar pasta
	[[ -a wavs ]] || mkdir wavs

	#deletar arquivo de lista caso tiver
	[[ -a list.txt ]] && rm -f list.txt

	#verificando se tem compactado gerado ou este algoritmo:
	[[ -a pre_data.zip ]] && rm -f pre_data.zip

	#buscar compactados, e descompactar:

	for compactados in *.zip;do
		[[ "${compactados}" = '*.zip' || ${compactados} ]] || {
			unzip -j "${compactados}" 1>&-
			rm -rf "${compactados}"  1>&-
			estavel=1
		}
	done

	#converter vídeos e demais formatos para .wav
	#e mover para o diretório wavs/
	#e deletar os originais
	echo -e "\nconvertendo, movendo e limpando ..."
	echo -e "\nmodo: HIPERBOOST! 3"

	contagem=0
	multi_thread=0
	for audio in *;do
		[[ "${audio}" =~ \.(webm|oga|ogg|opus|mp3|mp4|m4a|mpeg|flac|raw|avi|mkv|ps|aac|wma|mp2|aiff) ]] && {
			estavel=1
		(
			name="wavs/${audio%%\[*}.wav"
			ffmpeg -y -i "${audio}" -ac 1 -ar 44100 "${name// /\_}" 2>&-
			rm -f "${audio}" 1>&-
			#cinalera
			echo 'a' > thread
		)&
			contagem=$((contagem+1))
		}
		[[ "${audio}" = *".wav"* ]] && {
			mv "${audio}" "wavs/${audio// /\_}"
			rm -f "${audio}" 1>&-
		}
	done

	[[ "${estavel}" ]] || {

	echo -e "\n
	============================================================================
	ALERTA IMPORTANTE!
	nenhum arquivo foi encontrado, seja arquivos enviados, links ou quaisquer
	tipos de referências sobre o conteúdo a buscar, baixar, descompactar ou
	realocar.

	verifique se você enviou o arquivo de forma solta \"fora das pastas de forma
	solta\", ou se digitou o nome do personagem, ou se passou algum link ou
	quaisquer tipos de informações.
	============================================================================"

		exit 1
	}

	multi_thread=${contagem}

	#monitorando threads:
	unset contagem
	while :
	do
		soma=$(wc -l <<< "$(< thread)")
		contagem=$((contagem+soma))
		echo "${contagem}/${multi_thread} conversões terminadas ..."
		[[ "$contagem" = "${multi_thread}" ]] && break
	done

	#listar e unir todos em um só, e deletar todos os demais
	echo -e "unindo ..."
	for audios in wavs/*;do
		[[ "${audios}" = 'wavs/*' ]] || {
			array+=( "${audios}" )
		}
	done

	sox ${array[@]} -c 1 "wavs/reunido.wav" norm -0.1 1>&-
	rm -f ${array[*]} 1>&-
	#caso o de cima não funcionar
	for audios in wavs/*;do
		[[ "${audios}" = *"reunido.wav"* ]] || rm -f "${audios}" 1>&-
	done

	echo "removendo ruido ..."

	#remover ruídos com spleeter
	spleeter separate -o wavs/ wavs/reunido.wav
	rm -f wavs/reunido/accompaniment.wav
	for audios in wavs/*;do
		[[ "${audios}" = *"vocals.wav"* ]] || rm -f "${audios}" 1>&-
	done
	mv wavs/reunido/vocals.wav wavs/ 1>&-
	rm -r wavs/reunido 1>&-

	#dividir audio longo na pasta:
	echo "cortando vozes ..."
	sox wavs/vocals.wav -r 22050 -c 1 -b 16 wavs/corte.wav silence -l 1 0.100 0.1% 1 0.050 0.1% : newfile : restart 1>&-

	echo "limpando arquivo original ..."
	sleep 15s
	rm -f wavs/vocals.wav 1>&-

	echo "verificando tamanho dos audios ..."
	for audios in wavs/corte*;do
		[[ "$(sox --i "${audios}")" =~ ([0-9]{2}\:){2}[0-9]{2}\.[0-9]{2} ]] && {
			[[ "${BASH_REMATCH[0]}" > "00:00:12.00" ]] && {
				mark=1
				echo -e "audio ${audios} passou mais que 8 segundos. Tempo {${BASH_REMATCH[0]}} | [sub-dividindo] ..."
				sox "${audios}" -r 22050 -c 1 -b 16 wavs/subcorte.wav silence -l 1 0.050 0.5% 1 0.050 0.5% : newfile : restart 1>&-
				rm -r "${audios}"
			} 
			[[ "${BASH_REMATCH[0]}" < "00:00:01.99" ]] && {
				mark=1
				echo "audio  ${audios} menor que 1.99 segundos. [deletando] ..."
				rm -r "${audios}"
			}
		}
	done

	[[ ${mark} ]] && {
		echo -e "\nsub verificação ativada!"
		for audios in wavs/*;do
			[[ "$(sox --i "${audios}")" =~ ([0-9]{2}\:){2}[0-9]{2}\.[0-9]{2} ]] && {
				[[ "${BASH_REMATCH[0]}" > "00:00:12.00" ]] && {
					echo -e "audio ${audios} passou mais que 8 segundos. Tempo {${BASH_REMATCH[0]}} | [sub-dividindo] ..."
					sox "${audios}" -r 22050 -c 1 -b 16 wavs/subcorte.wav silence -l 1 0.050 0.8% 1 0.050 0.8% : newfile : restart 1>&-
					rm -r "${audios}"
				} 
				[[ "${BASH_REMATCH[0]}" < "00:00:01.99" ]] && {
					echo "audio  ${audios} menor que 1.99 segundos. [deletando] ..."
					rm -r "${audios}"
				}
			}
		done

	}

	echo "compactando ..."
	zip -r pre_data.zip wavs/ 1>$-

	rm -r wavs/* 1>&-

	echo -e "\n
	============================================================================
	ALERTA IMPORTANTE!
	no momento, todos os audios foram separados, um arquivo
	zip foi criado -> (pre_data.zip) estou baixando ele para você!

	apague os que não forem do seu personagem, os que forem, mande 
	novamente para o colab, compactado ou solto \"mude o
	nome, o arquivo pre_data será deletado\", e assim que o fizer,
	rode a próxima célula abaixo para continuar o restante!

	OBS: tenha em vista que dependendo dos barulhos, não são removidos
	direito, então terá alguns áudios apenas com sons estranhos, então
	os remova também!
	============================================================================"
}

[[ ${5,,} =~ (false|true) ]] && {

	[[ ${6} -eq 1 ]] && {

		[[ -a pre_data.zip ]] && unzip pre_data.zip
		#TRANSCREVER:

		#verificando se tem compactado gerado ou este algoritmo:
		[[ -a pre_data.zip ]] && rm -f pre_data.zip

		#verificar existência da pasta wavs, e deletar arquivos de audios que estiverem internamente:
		[[ -a wavs ]] || mkdir wavs

		echo -e "descompactando ..."
		#buscar compactados, e descompactar:
		for compactados in *.zip;do
			echo "entrou, arquivo: ${compactados}"
			[[ "${compactados}" = *"*.zip"* ]] && break
			unzip -j "${compactados}" || {
				echo -e "um erro ocorreu com seu arquivo compactado ..."
				exit
			}
			rm -rf "${compactados}" 1>&-
		done

		#movendo arquivos
		echo -e "movendo ..."
#		for audio in *.wav;do
#			mv "${audio}" "wavs/${audio}" 1>&-
#		done

		mv *.wav wavs/ 1>&-

		[[ ${5,,} = "true" ]] && {
			echo "gerando lista ..."
			for envio in wavs/*;do
				echo "${envio}|" >> list.txt
			done
			sed -i '/^\s*$/d' list.txt
			echo "lista gerada!"
			exit
		}

		#reduzir a velocidade dos audios para melhor transcrição:
		echo -e "reduzindo velocidade do som ..."
		for audios in wavs/*;do
			[[ "${audios}" = *".wav"* ]] || {
				ffmpeg -y -i "${audios}" "${audios%%.*}.wav" 1>&-
				rm -f "${audios}" 1>&-
			}

			sox "${audios%%.*}.wav" "${audios%%.*}_slow.wav" speed 0.85 1>&-
		done

		#primeiro, ele irá converter os audios em uma forma que a google entenda:
		echo -e "convertendo de slow.wav para slow.flac ..."
		for audio in wavs/*_slow.wav;do
			ffmpeg -y -i "${audio}" -r 48k "${audio%%.*}.flac" 1>&- 2>&-
			rm -f "${audio}" 1>&-
		done

		#buscar arquivos convertidos, e aplicar silêncio neles.
		echo -e "aplicando silêncio nos arquivos slow.flac ..."
		for preparo in wavs/*.flac;do
			sox ${preparo} "${preparo%%.*}_silent.flac" pad 0.6 0.6 1>&-
			rm -f "${preparo}" 1>&-
			mv "${preparo%%.*}_silent.flac" "${preparo}" 1>&-
		done

		rm -rf wavs/*slow.wav

		#transcrever
		echo -e "transcrevendo ..."
		for envio in wavs/*.flac;do
			transcricao=$(curl -s -X POST --data-binary @"${envio}" --user-agent 'Mozilla/5.0' --header 'Content-Type: audio/x-flac; rate=48000;' "https://www.google.com/speech-api/v2/recognize?output=json&lang=pt-BR&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&client=Mozilla/5.0" | jq '.result[].alternative[].transcript')
			rm -f "${envio}" & 1>&-

			while read linha;do
				texto=${linha//\"/}
			done <<< "${transcricao,,}"

			echo "${envio%%_slow*}.wav|${texto:+$texto.}"
			echo "${envio%%_slow*}.wav|${texto:+$texto.}" >> list.txt
			[[ ${texto} ]] && {
				printf " %s " "OK"
			}
		done
		zip dataset.zip wavs/* list.txt

	echo -e "\n
	============================================================================
	ALERTA IMPORTANTE!
	os audios foram convertidos para mono, em 4450Khz e para 16 bits
	(pode ser que aredonde para 32), um arquivo. 
	um zip foi criado -> (dataset.zip), estou baixando ele para você!

	agora ele vem acompanhado do arquivo list.txt onde você deve transcrever
	as linhas que faltam ser transcritas, e os que ja possuirem transcrição,
	você deve verificar e corrigir os erros de escrita e confusão de palavras!

	OBS: você deve lembrar sempre que no final das suas transcrições, eles 
	terminam com um destes caracteres: ,.!
	============================================================================"
	}

	[[ ${6} -eq 2 && "${7}" ]] && {
		echo "arquivo a parear: ${7}"
		while read linha;do
			[[ "${linha}" = *"${7}"* ]] && {
				echo -e "\npré-transcrição: ${linha##*\|}\n"
				break
			}
		done < list.txt
		[[ ${linha##*\|} ]] || echo -e "\n\n NENHUMA TRANSCRIÇÃO ENCONTRADA! \n\n"
	}

	[[ ${6} -eq 3 ]] && {
		#verificar as terminações de cada linha
		while read linha;do
			quantidade="${#linha}"
			quantidade=$[quantidade-1]
			#caso terminar com ',', trocar por '.'
			[[ "${linha:$quantidade:$quantidade}" = ','  ]] && {
				sed -i "s/${linha}/${linha%,*}." list.txt
			}

			#caso não terminar com nenhum símbolo, adicionar '.'
			[[ "${linha:$quantidade:$quantidade}" =~ (\.|\?|\!) ]] || {
				sed -i "s/${linha}/${linha}." list.txt
			}
		done < list.txt
	}
}
