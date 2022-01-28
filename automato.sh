#! /bin/bash

programs=(  sox spleeter ffmpeg jq  youtube-dl )
for verificar in ${programs[@]};do
	command -v ${verificar} || {
		echo -e "programa ${verificar} não instalado\nrealizando instalação automática ..."
		[[ ${verificar} =~ (sox|jq|ffmpeg) ]] && apt install ${verificar}
		[[ ${verificar} =~ (spleeter|youtube-dl) ]] && pip install ${verificar}
	}
done

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

	[[ "${F1}" =~ drive.*sharing ]] && {
		youtube-dl "${F1}"
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
	}

	[[ ${2} && ${3} && ${4} -ge 1 ]] && {
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
		[[ "${audio}" =~ \.(oga|ogg|opus|mp3|mp4|m4a|mpeg|flac|raw|avi|mkv|ps|aac|wma|mp2|aiff) ]] && {
			ffmpeg -i "${audio}" "wavs/${audio%%.*}.wav"
			rm -f "${audio}"
		}
		[[ "${audio}" = *".wav"* ]] && {
			mv "${audio}" "wavs/${audio// /\_}"
			rm -f "${audio}"
		}

	done

	#listar e unir todos em um só, e deletar todos os demais
	echo -e "\n\nunindo ..."
	for audios in wavs/*;do
		array+=( "${audios}" )
	done
	sox ${array[@]} "wavs/reunido.wav"
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
	rm -r wavs/reunido

	#dividir audio longo na pasta:
	echo -e "\n\nseparando vozes ..."
	sox wavs/vocals.wav -r 22050 -c 1 -b 16 wavs/corte.wav silence -l 1 0.50 0.5% 1 0.050 0.5% : newfile : restart
	rm -f wavs/vocals.wav

	zip -r pre_data.zip wavs/

	rm -r wavs/*

	echo -e "\n
	============================================================================
	ALERTA IMPORTANTE!
	no momento, todos os audios foram separados, um arquivo
	zip foi criado -> (pre_data.zip) estou baixando ele para você!

	apague os que não forem do seu personagem, os que forem, mande 
	novamente para o colab, compactado ou solto \"mude o
	nome, o arquivo pre_data será deletado\", e assim que o fizer,
	rode a próxima célula abaixo para continuar o restante!
	============================================================================"
}

[[ ${5,,} =~ (false|true) ]] && {
	#TRANSCREVER:

	#verificando se tem compactado gerado or este algoritmo:
	[[ -a pre_data.zip ]] && rm -f pre_data.zip

	#verificar existência da pasta wavs, e deletar arquivos de audios que estiverem internamente:
	[[ -a wavs ]] || mkdir wavs

	echo -e "\n\n descompactando ..."
	#buscar compactados, e descompactar:
	for compactados in *.zip;do
		echo "entrou, arquivo: ${compactados}"
		[[ "${compactados}" = *"*.zip"* ]] && break
		unzip -j "${compactados}" || {
			echo -e "\n\n  um erro ocorreu com seu arquivo compactado ..."
			exit
		}
		rm -rf "${compactados}"
	done

	#movendo arquivos
	echo -e "\n\n movendo ..."
	for audio in *.wav;do
		mv "${audio}" "wavs/${audio}"
	done

	[[ ${5,,} = "true" ]] && {
		echo "gerando lista ..."
		for envio in wavs/*;do
			echo "${envio}|" >> list.txt
		done
		echo "lista gerada!"
		exit
	}

	#reduzir a velocidade dos audios para melhor transcrição:
	echo -e "\n\nreduzindo velocidade do som ..."
	for audios in wavs/*;do 
		[[ "${audios}" = *".wav"* ]] || {
			ffmpeg -y -i "${audios}" "${audios%%.*}.wav"
			rm -f "${audios}"
		}

		sox "${audios%%.*}.wav" "${audios%%.*}_slow.wav" speed 0.85
	done

	#primeiro, ele irá converter os audios em uma forma que a google entenda:
	echo -e "\n\nconvertendo de slow.wav para slow.flac ..."
	for audio in wavs/*_slow.wav;do
		ffmpeg -y -i "${audio}" -r 48k "${audio%%.*}.flac"
		rm -f "${audio}"
	done

	#buscar arquivos convertidos, e aplicar silêncio neles.
	echo -e "\n\naplicando silêncio nos arquivos slow.flac ..."
	for preparo in wavs/*.flac;do
		sox ${preparo} "${preparo%%.*}_silent.flac" pad 0.6 0.6
		rm -f "${preparo}"
		mv "${preparo%%.*}_silent.flac" "${preparo}"
	done

	rm -rf wavs/*slow.wav

	#transcrever
	echo -e "\n\ntranscrevendo ..."
	for envio in wavs/*.flac;do
		transcricao=$(curl -s -X POST --data-binary @${envio} --user-agent 'Mozilla/5.0' --header 'Content-Type: audio/x-flac; rate=48000;' "https://www.google.com/speech-api/v2/recognize?output=json&lang=pt-BR&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&client=Mozilla/5.0" | jq '.result[].alternative[].transcript')
		rm -f "${envio}" &

#		echo "${transcricao}"

		while read linha;do
			texto=${linha//\"/}
		done <<< "${transcricao,,}"

		echo "${envio%%_slow*}.wav|${texto:+$texto\.}"
		[[ ${texto} ]] && {
			echo "${envio%%_slow*}.wav|${texto:+$texto\.}" >> list.txt
			printf " %s" "OK"
		}

	done
}

#git clone 'https://github.com/lucassantilli/UVR-Colab-GUI' UVR_V5
#pip install -r UVR_V5/requirements.txt
#wget 'https://github.com/lucassantilli/UVR-Colab-GUI/releases/download/m5.1/HP2-MAIN-MSB2-3BAND-3090.pth'
#cd UVR_V5/;python3 inference.py -i "/content/teste.mp3" -P "/content/HP2-MAIN-MSB2-3BAND-3090.pth" -g 0 -m "modelparams/3band_44100.json" -n 537238KB -w 320 -t -H mirroring -A 0.2
