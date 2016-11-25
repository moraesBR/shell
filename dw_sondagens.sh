#!/bin/bash
# Script dw_sondagem.sh
# Autor: Eng. Albert R. M. Lopes <albert.richard@gmail.com>
# Criado em: 01/11/2011
# Modificado em: 
#	       01/11/2011
#		  - Flexibilidade para determinar o local onde será armazenado as sondagens
#	       06/04/2012
#		  - Flexibilidade para especificar o dia de download ou intervalo de dias
#		  - Flexibilidade para determinar os horário de sondagens
#			* Padrão: Somente para as 00
#		  - Flexibilidade para especificar o conjunto de estações
#			* Padrão: 82244,82281,82099,82193,82022,82332,83065
#	       08/04/2012
#		  - Alterações dos nomes das seguintes variáveis
#			* ESTACOES --> ID_ESTACOES
#			* SAIDA    --> ESTACAO
#			* estacao  --> id_estacao
#	       21/11/2016
#		  - Funcionamento interno: os downloads das sondagens (arquivo temporário) por mês-a-mês ao invés de dia-a-dia.
#		  - Script não está funcionando
#		  
#	       24/11/2016
#		  - Novo mecanismo de download de dados brutos implementado e não testado.
#		  - Novo mecanismo de extração das sondagens (via função ext_sondagem) implementado e não testado.
#		  - Alteração do nome de get_sounding.sh para dw_sondagem.sh
#		  - Alteração completa do conteúdo da função ajuda.
#		  - Inserção de opções de segurança nas opções de execução
#
#	       25/11/2016
#		  - Mecanismo de download de dados brutos funcionando
#		  - Mecanismo de extração das sondagens (via função ext_sondagem) funcionando
# 		  - Inserção do endereço para contribuições e relatar bugs.
#
# Sintaxe: dw_sondagens.sh [-v=<val> | --valor=<val>]
#	   Para mais detalhes use: get_sounding.sh --help

clear

USO="$0"
LINK="http://weather.uwyo.edu/cgi-bin/sounding?region=samer&TYPE=TEXT%3ALIST"

# -----------------------------------------------------------------------------------------------------

# ---------------------------------------- FUNÇÕES DE OPÇÕES ------------------------------------------

# MOSTRA AS OPÇÕES UTILIZAVÉIS DO COMANDO
ajuda() {

	COLUNAS=76

	# Imprime o separador de sessão, que é constituído de 76 '-'
	t=$(printf "%-"$COLUNAS"s" "-")
	printf "%-"$COLUNAS"s\n" ${t// /-}

	# Centraliza o texto referente ao nome do script
	script_nome="SCRIPT: $(echo "$USO" | awk -F '/' '{printf $NF}' )"
	printf "%*s\n" $(((${#script_nome}+$COLUNAS)/2)) "$script_nome"

	t=$(printf "%-"$COLUNAS"s" "-")
	printf "%-"$COLUNAS"s\n" ${t// /-}
	
	# Descrição do script	
	descricao="Baixa as radiossondagens armazenadas nos servidores do departamento de ciências atmosféricas da Universidade  			   de Wyoming (http://weather.uwyo.edu)"
	printf "%s\n\n" "$descricao" | fmt -u -w $COLUNAS

	# Modo de uso
	modo_uso="Uso: $USO <-e=\"...\"> <-h=\"...\"> <-d=...|-p=...> [-l=\"...\"]"
	texto1="As opções entre <> e [] são obrigatórias e facultativas, respectivamente."
	texto2="O simbolo | indica que somente umas das opções entre <> pode ser utilizada por vez."
	printf "%-"$COLUNAS"s\n\n" "$modo_uso"
	printf "%-"$COLUNAS"s\n%-"$COLUNAS"s\n\n" "$texto1" "$texto2" | fmt -u 
	
	# Descrição das opções disponíveis
	printf "%*s  %*s  %*s\n" 12 'OPÇÃO' 20 'ARGUMENTO' 30 'DESCRIÇÃO'
	printf "%5s %-10s  %-23s  %-31s\n" '-e,' '--estation' '="ID1 ID2 ... IDn"' 'IDs das estações meteorológicas'
	printf "%5s %-10s  %-23s  %-31s\n" '-h,' '--hour' '=00 =12 ou ="00 12"' 'Horário UTC da radiossondagem'
	printf "%5s %-10s  %-23s  %-31s\n" '-d,' '--date' '=AAAA/MM/DD' 'Data da radiossondagem desejada'
	printf "%5s %-10s  %-23s  %-31s\n" '-p,' '--period' '=aaaa/mm/dd-AAAA/MM/DD' 'Periodo das radiossondagens: inicio-fim'
	printf "%5s %-10s  %-23s  %-31s\n" '-l,' '--local' '="/PATH/STORE/"' 'Local para armazenamento'
	printf "%5s %-10s  %-23s  %-31s\n\n" '-l,' '--help' '' 'Opção de ajuda'

	# Exemplos de estações meteorológicas
	printf "%-"$COLUNAS"s\n\n" 'Alguns exemplos de ids de estações meteorológicas'
	printf "    %-10s\t\t%-5s\n" 'ESTAÇÃO' 'ID'
	printf "  - %-10s\t\t%-5s\n" 'Belém:' '82193'
	printf "  - %-10s\t\t%-5s\n" 'Boa Vista:' '82022'
	printf "  - %-10s\t\t%-5s\n" 'Manaus:' '82332'
	printf "  - %-10s\t\t%-5s\n" 'Santarém:' '82244'
	printf "  - %-10s\t\t%-5s\n\n" 'São Luiz:' '82281'

	# Exemplos de uso do script
	exemplo="$USO -e=82193 -h=\"00 12\" -p=2016/04/03-2016/06/27"
	texto='Baixa as radiossondagens realizadas em Belém no período entre 2016/04/03 e 2016/06/27 nos horários de 00Z e 12Z. As 		       radiossodagens serão armazenadas no diretório corrente por padrão.'
	printf "%-"$COLUNAS"s\n\n" 'Exemplo de uso:'
	printf "%*s\n\n" $(((${#exemplo}+$COLUNAS)/2)) "$exemplo"
	printf "%-"$COLUNAS"s\n\n" "$texto" | fmt -u -w $COLUNAS

	# Outras informações
	printf "%-"$COLUNAS"s\n" 'Autor: Albert Richard M. L. <albert.richard@gmail.com>'
	printf "%-"$COLUNAS"s\n\n" 'Para contribuições e relatar bugs: <https://github.com/moraesBR/shell/blob/master/dw_sondagens.sh>'
	exit
}

# ALGORITMO DE EXTRAÇÃO DAS RADIOSSONDAGENS
# 1) Recebe o endereço completo do arquivo de dados brutos e o conjunto de horários das radiossondagens que o usuário deseja.
# 2) Filtra os cabeçalhos de todas as sondagens
# 3) Armazena todas as posições iniciais e finais das sondagens
# 4) Extrai as radiossondagens se o horário descrito no cabeçalho da radiossondagem coincidir com alguns dos horários deseja 
#    pelo usuário.
# 5) Armazena as sondagem nos arquivos com o seguinte formato: <Nome da Estação>-<ANO><MES><DIA><HORÁRIO>.txt
ext_sondagem(){

   ARQUIVO="$1"
   shift
   HORAS=("$@")

   CAMINHO=$(echo $ARQUIVO | awk -F "/" '{for(i=1;i<NF;i++){printf "/%s",$i}; printf "\n"}')
   

   TITULO=($(grep '<H2>[^H2>].*[^</H2]</H2>' "$ARQUIVO" | sed 's/<\/*H2>//g' | awk '{print $1":"$2":"$(NF-1)":"$(NF-2)":"$(NF-3)":"$NF}' | sed 's/Z//g'))
   LINI=($(grep -n "^<PRE>" "$ARQUIVO" | awk -F: '{print $1}'))
   LFIM=($(grep -n "^</PRE><H3>" "$ARQUIVO" | awk -F: '{print $1}'))
   LTAM=${#TITULO[@]}


   for i in $(seq $LTAM)
   do 
	read ESTACAO_NOME <<< $(echo ${TITULO[$(expr $i-1)]} | awk -F ":" '{print $2}')
	read ANO MES DIA HORA <<< $(date -d "$(echo ${TITULO[$(expr $i-1)]} | awk -F ':' '{print $(NF-3),$(NF-2),$(NF-1),$NF}')" +'%Y %m %d %H')
	
	for h in ${HORAS[*]}; do
		test "$h" -eq "$HORA"  &&
			(head -$(expr ${LFIM[$(expr $i-1)]} - 1) "$ARQUIVO" | tail -$(expr ${LFIM[$(expr $i-1)]} - ${LINI[$(expr $i-1)]} - 1) > "$CAMINHO/$ESTACAO_NOME-$ANO$MES$DIA$HORA.txt")
	done
   done

   rm $ARQUIVO

}

# ---------------------------------------------------------------------------------------------------------

# -------- FILTRO DE OPÇÕES ----------

while test $# -gt 0 ; do
	optarg=`echo $1 | cut -d= -f2 `
	case "${1}" in
	-d=*|--date=*)
		DATAINICIAL=$(date -I -d "$optarg") || 
			    (echo "Data inicial inválida" && exit)
		DATAFINAL=$DATAINICIAL
	;;
	-e=*|--estation=*)
		# Remove repetições
		optarg=$(echo $optarg | 
			 tr ' ' '\n' | 	# Transforma colunas em linhas
			 sort -u ) 	# Ordena e remove duplicações
		ID_ESTACOES=$optarg
	;;
	-h=*|--hour=*)

		# Remove repetições
		optarg=$(echo $optarg | 
			 tr ' ' '\n' | 	# Transforma colunas em linhas
			 sort -u | 	# Ordena e remove duplicações
			 tr '\n' ' ') 	# Transforma linhas em colunas			 

		for h in $optarg;
		do
			( test $h = "00" || test $h = "12" ) && 
				HORARIOS+="$h "
 		done
	
		HORARIOS=$(echo $HORARIOS | tr ' ' '\n')
	;;
	--help)
		ajuda
	;;
	-l=*|--local=*)
		test ! -d "$optarg" && 
			echo "Local de armazenamento inacessível!" &&
			exit
		LOCAL=$optarg
	;;
	-p=*|--period=*)
		DATAINICIAL=$(date -I -d "$(echo $optarg | cut -d- -f1)") || 
			    (echo "Data inicial inválida" && exit)

		DATAFINAL=$(date -I -d "$(echo $optarg | cut -d- -f2)") || 
			    (echo "Data final inválida" && exit)
	;;
	-*)
		echo "Argumento $1 inválido."
		echo "Use a opção $USO --help!"
		exit	
	;;
	*)
		echo "Argumento $1 inválido."
                echo "Use a opção $USO--help!"
                exit
	;;	
	esac
	shift
done
# --------------------------------------------------------------------------------------------


# ---------------------------------- CODIGO PRINCIPAL ----------------------------------------
# GARANTE QUE AS VARIÁVEIS DE ENTRADA NÃO ESTÃO VAZIAS E, POR CONSEQUÊNCIA, O FUNCIONAMENTO
# DO SCRIPT.
test -z "$LOCAL" && 
	echo "Armazenando no diretório $PWD" &&
	LOCAL=$(pwd)

test -z "$ID_ESTACOES" && 
	echo "Informe o(s) ID(s) da(s) estação(ões)" && 
	echo "Para mais informações use: $USO --help" &&
	exit

test -z "$HORARIOS"&& 
	echo "Informe o(s) horário(s) das radiossondagens" && 
	echo "Para mais informações use: $USO --help" &&
	exit

test -z "$DATAINICIAL"&& 
	echo "Informe a data ou o período das radiossondagens" && 
	echo "Para mais informações use: $USO --help" &&
	exit

test -z "$DATAFINAL"&& 
	echo "Informe a data ou o período das radiossondagens" && 
	echo "Para mais informações use: $USO --help" &&
	exit

HORA_INICIAL=$(echo "$HORARIOS" | head -1)	# Determina a menor hora UTC informada
HORA_FINAL=$(echo "$HORARIOS" |  tail -1)	# Determina a maior hora UTC informada

# Algoritmo para o download dos dados brutos.
# 1) Entra com uma data inicial no formato AAAA/MM/DD.
# 2) Enquanto a data inicial (sem '\') for menor ou igual a data final ('sem '\''), faça:
#	a) Estabele o inicío e o fim do período no mês:
#		- No primeiro ciclo, o inicío coincide com a data inicial.
#		- O fim do ciclo coincide com o fim do mês, caso não seja superior a data final. 
#		      Se for, a data final será o fim.
#	b) Efetua o download da radiossondagens no período determinado no passo 2.a:
#		- O download é armazenado em um arquivo temporário no diretórío $LOCAL.
#	c) Chama a função ext_sondagem para separar as sondagens desejadas pelo usuário.
D_INICIAL="$DATAINICIAL"
while [ "$(date -d "$D_INICIAL" +'%Y%m%d')" -le "$(date -d "$DATAFINAL" +'%Y%m%d')" ] 
do
	TEMP=$(date -d "$D_INICIAL" +'%Y-%m-01')
	D_FINAL=$(date -I -d "$TEMP + 1 month yesterday")
	if [ "$(date -d "$D_FINAL" +'%Y%m%d')" -le "$(date -d "$DATAFINAL" +'%Y%m%d')" ]
	   then 
		echo "$D_INICIAL --- $D_FINAL"
		for ESTACAO in $ID_ESTACOES; do
			read IANO IMES IDIA IHORA <<< $(date -d "$D_INICIAL $HORA_INICIAL" +'%Y %m %d %H')
			read FANO FMES FDIA FHORA <<< $(date -d "$D_FINAL $HORA_FINAL" +'%Y %m %d %H')
			wget -c "$LINK&YEAR=$IANO&MONTH=$IMES&FROM=$IDIA$IHORA&TO=$FDIA$FHORA&STNM=$ESTACAO" -O "$LOCAL/$ESTACAO-$IANO$IMES.txt"
			VET=($(echo "$HORARIOS"))
			ARQ="$LOCAL/$ESTACAO-$IANO$IMES.txt"
			ext_sondagem "${ARQ}" "${VET[@]}" 
		done
	   else 
		echo "$D_INICIAL --- $DATAFINAL"
		for ESTACAO in $ID_ESTACOES; do
			read IANO IMES IDIA IHORA <<< $(date -d "$D_INICIAL $HORA_INICIAL" +'%Y %m %d %H')
			read FANO FMES FDIA FHORA <<< $(date -d "$DATAFINAL $HORA_FINAL" +'%Y %m %d %H')
			wget -c "$LINK&YEAR=$IANO&MONTH=$IMES&FROM=$IDIA$IHORA&TO=$FDIA$FHORA&STNM=$ESTACAO" -O "$LOCAL/$ESTACAO-$IANO$IMES.txt"
			VET=($(echo "$HORARIOS"))
			ARQ="$LOCAL/$ESTACAO-$IANO$IMES.txt"
			ext_sondagem "${ARQ}" "${VET[@]}"
		done
	fi
	D_INICIAL=$(date -I -d "$TEMP + 1 month")
done
