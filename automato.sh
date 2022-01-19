#! /bin/bash

baixar(){

	#coletar ID
	[[ "${F1}" =~ /(watch|playlist)\?(v|list)=([a-zA-Z0-9_-]+) ]]
	ID="${BASH_REMATCH[3]}"
	TIPO="${BASH_REMATCH[1]}"

#  [[ "${TIPO}" = "watch" ]] && echo "https://www.youtube.com/watch?v=${ID}"
#  [[ "${TIPO}" = "playlist" ]] && echo "https://www.youtube.com/playlist?list=${ID}"

	[[ "${TIPO}" = "watch" ]] && {
		midia=$(youtube-dl --get-url "https://www.youtube.com/watch?v=${ID}")
		while read linha;do
			link="${linha}"
		done <<< "${midia}"

		wget "${link}" -O "audio_${contagem}.mp3"
	}

	[[ "${TIPO}" = "playlist" ]] && {
		echo "playlist detectada, realizando varreduras ..."

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

		contagem=0
		for video in ${videos[@]};do 
			midia=$(youtube-dl --get-url "${video}")
			while read linha;do
				link="${linha}"
			done <<< "${midia}"

			wget "${link}" -O "audio_${contagem}.mp3"
			contagem=$((contagem+1))
		done
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
		IFS=',' read F1 F2 <<< "${1}"
		while :
		do
			#verificar variavel, se vazia, pular
			[[ ${F1} ]] && {
				#fazer o download do primeiro link, depois, repassar para a primeira variavel
			    echo "analyzing 🔎 ..."

			    [[ ${F1} = *"youtu"* ]] && {
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
	}

	[[ ${2} && ${3} ]] && {
		[[ "${2,,}" = "seriado" ]] && busca="cenas iconicas compilado ${3}"
		[[ "${2,,}" = "filme" ]] && busca="cenas frases trainler compilado ${3}"
		[[ "${2,,}" =~ (desenho|seriado) ]] && busca="episodios mensagens cenas ${3}"
		[[ "${2,,}" = "youtuber" ]] && busca="${3}"
		[[ "${2,,}" = "documentario" ]] && busca="episodio discover temporada ${3}"

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

			contagem=0

			for down in ${videos[@]};do
		    midia=$(youtube-dl --get-url "${down}")

				while read linha;do
					link="${linha}"
				done <<< "${midia}"

				wget "${link}" -O "audio_${contagem}.mp3"
				contagem=$((contagem+1))
			done
		}
	}

	#verificar pasta
	[[ -a wavs ]] || mkdir wavs

	#deletar arquivo de lista caso tiver
	[[ -a list.txt ]] && rm -f list.txt

	#verificando se tem compactado gerado or este algoritmo:
	[[ -a pre_data.zip ]] && rm -f pre_data.zip

	#buscar compactados, e descompactar:
	for compactados in *.zip;do
		unzip -j "${compactados}"
		rm -rf "${compactados}"
	done

	#converter vídeos e demais formatos para .wav
	#e mover para o diretório wavs/
	#e deletar os originais
	echo -e "\n\nconvertendo, movendo e limpando ..."
	for audio in *;do
		[[ "${audio}" =~ \.(oga|ogg|mp3|mp4|m4a|flac|raw|avi|mkv|ps) ]] && {
			ffmpeg -i "${audio}" wavs/"${audio%%.*}.wav"
			rm -f "${audio}"
		}
		[[ "${audio}" = *".wav"* ]] && {
			mv "${audio}" "wavs/${audio}"
			rm -f "${audio}"
		}

	done

	#listar e unir todos em um só, e deletar todos os demais
	echo -e "\n\nunindo ..."
	for audios in wavs/*;do
		array+=( "${audios}" )
	done
	sox ${array[@]} wavs/reunido.wav
	rm -f ${array[*]}
	#caso o de cima não funcionar
	for audios in wavs/*;do
		[[ "${audios}" = *"reunido.wav"* ]] || rm -f "${audios}"
	done

	#remover ruídos com spleeter
	spleeter separate -o wavs/ wavs/reunido.wav
	rm -f wavs/reunido/accompaniment.wav
	for audios in wavs/*;do
		[[ "${audios}" = *"vocals.wav"* ]] || rm -f "${audios}"
	done
	mv wavs/reunido/vocals.wav wavs/
	rm -r wavs/reunido/

	#dividir audio longo na pasta:
	echo -e "\n\nseparando vozes ..."
	sox wavs/vocals.wav wavs/personagem.wav silence -l 1 0.70 0.5% 1 0.070 0.5% : newfile : restart
	rm -f wavs/vocals.wav

	zip -r pre_data.zip wavs/

	rm -r wavs/*

	echo -e "\n\nALERTA IMPORTANTE!
	no momento, todos os audios foram separados, um arquivo
	zip foi criado -> (pre_data.zip) para você baixar com os audios cortados, apague os 
	que não forem do seu personagem, os que forem, mande novamente para a
	pasta wavs depois e assim que o fizer, rode a próxima célula abaixo
	para continuar o restante!"
}

[[ ${5} -eq 2 ]] && {
	#TRANSCREVER:


	#verificando se tem compactado gerado or este algoritmo:
	[[ -a pre_data.zip ]] && rm -f pre_data.zip

	echo -e "\n\n descompactando ..."
	#buscar compactados, e descompactar:
	for compactados in *.zip;do
		unzip -j "${compactados}" || {
			echo -e "\n\n  um erro ocorreu com seu arquivo compactado ..."
			exit
		}
		rm -rf "${compactados}"
	done

	#movendo arquivos
	echo -e "\n\n movendo ..."
	for audio in vocal*;do
		mv "${audio}" "wavs/${audio}"
	done

	#reduzir a velocidade dos audios para melhor transcrição:
	echo -e "\n\nreduzindo velocidade do som ..."
	for audios in wavs/*;do 
		[[ "${audios}" = *".wav"* ]] || {
			ffmpeg -i "${audios}" "${audios%%.*}.wav"
			sox "${audios%%.*}.wav" "${audios%%.*}_slow.wav" speed 0.85
			rm -f "${audios}"
		} || {
			echo "nenhum audio na pasta wavs encontrada!"
		}
	done

	#primeiro, ele irá converter os audios em uma forma que a google entenda:
	for audio in audio/*wav;do
		ffmpeg -i wavs/${audio} -r 48k wavs/${audio%%.*}.flac
	done

	#buscar arquivos convertidos, e aplicar silêncio neles.
	for preparo in audio/*flac;do
		sox ${preparo} "${preparo%.*}_silent.wav" pad 0.6 0.6
		ffmpeg -y -i "${preparo%.*}.wav" "${preparo%.*}.flac"
		rm -f "${preparo%.*}_silent.wav"
	done

	#transcrever
	for envio in wavs/*flac;do
		transcricao=$(curl -s -X POST --data-binary @${envio} --user-agent 'Mozilla/5.0' --header 'Content-Type: audio/x-flac; rate=48000;' "https://www.google.com/speech-api/v2/recognize?output=json&lang=pt-BR&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&client=Mozilla/5.0" | jq '.result[].alternative[].transcript')
		rm -f "${envio}" &

		while read linha;do
			texto=${linha//\"/}
		done <<< "${transcricao,,}"

		echo "${envio%%.*}.wav|${texto:+$texto\.}" >> list.txt
		rm -f "${envio%.*}_silent.wav"
	done

	#gerar dataset: <----- DESATIVADO, para gerar o dataset conforme as transcrições
	#for audios in wavs/*;do
	#	echo "${audios}|" >> list.txt
	#done
}
