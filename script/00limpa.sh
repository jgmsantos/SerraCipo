#!/bin/bash

DIR_INPUT="../input"
DIR_OUTPUT="../output"
DIR_SHAPE="../shape/netcdf"
DIR_TMP="../tmp"

for arquivo in PREC.IMERG.20200701.20201031.nc TEMP2M.GFS.ANL.20200701.20201031.nc
do

   if [ $arquivo = PREC.IMERG.20200701.20201031.nc ]
   then
      operador="eca_cdd"
      valor="1,5"
   fi

   if [ $arquivo = TEMP2M.GFS.ANL.20200701.20201031.nc ]
   then
      operador="eca_csu"
      valor="30,5"
   fi

   echo $arquivo

   # Interpola o dado para a mesma resolução do shapefile (engloba uma área maior que a Serra do Cipó) 
   # fornecido pelo Paulo Cunha.
   # Não existe dados meteorológicos para a Serra do Cipó, a solução encontrada foi essa, a interpolação.
   cdo -s remapbil,$DIR_SHAPE/APA_MorroPedreira_PARNA_SerraCipo.nc $DIR_INPUT/$arquivo $DIR_TMP/tmp01.nc

   # Aplica a máscara ao dado.
   cdo -s ifthen $DIR_SHAPE/APA_MorroPedreira_PARNA_SerraCipo.nc $DIR_TMP/tmp01.nc $DIR_OUTPUT/$arquivo

   # Mesma ideia da aplicação acima, com a diferença que foi aplicada a máscara da Serra do Cipó.
   # O resultado é a série temporal diária da Serra do Cipó entre os meses de julho a outubro.
   cdo -s remapbil,$DIR_SHAPE/PARNA_SerraCipo.nc $DIR_INPUT/$arquivo $DIR_TMP/tmp02.nc
   cdo -s -fldmean -ifthen $DIR_SHAPE/PARNA_SerraCipo.nc $DIR_TMP/tmp02.nc $DIR_OUTPUT/serie_temporal_$arquivo
      
   # Número de dias sem chuva consecutivo para todo o perído desde 20200701 a 20201031:
   cdo -s $operador,$valor $DIR_OUTPUT/serie_temporal_$arquivo $DIR_OUTPUT/$operador.$arquivo

   # Separa individualmente o arquivo com os meses de julho a outubro
   cdo -s splitmon $DIR_OUTPUT/serie_temporal_$arquivo $DIR_TMP/mes.

   # Aplica o índice eca_cdd de número consecutivo sem chuva com limiar de R <= 1mm/dia para cada mês. Esse índice é 
   # aplicado na série temporal de chuva da Serra do Cipó.
   for mes in 07 08 09 10
   do
      cdo -s $operador,$valor $DIR_TMP/mes.$mes.nc $DIR_TMP/$operador.mes.$mes.nc 
   done

done

# Junta os arquivos.
cdo -s -O mergetime $DIR_TMP/eca_cdd.mes.??.nc $DIR_OUTPUT/eca_cdd.nc
cdo -s -O mergetime $DIR_TMP/eca_csu.mes.??.nc $DIR_OUTPUT/eca_csu.nc

# Converte a série temporal de precipitação de NetCDF para texto:
cdo -s output $DIR_OUTPUT/serie_temporal_PREC.IMERG.20200701.20201031.nc | sed 's/\./,/g' > $DIR_OUTPUT/serie_temporal_PREC.IMERG.20200701.20201031.txt

# Convert de Kelvin para Celsius a série temporal de temperatura da Serra do Cipó.
cdo -s subc,273.15 $DIR_OUTPUT/TEMP2M.GFS.ANL.20200701.20201031.nc $DIR_TMP/tmp.nc
mv $DIR_TMP/tmp.nc $DIR_OUTPUT/TEMP2M.GFS.ANL.20200701.20201031.nc
cdo -s -output -fldmean $DIR_OUTPUT/TEMP2M.GFS.ANL.20200701.20201031.nc | sed 's/\./,/g' > $DIR_OUTPUT/serie_temporal_TEMP2M.GFS.ANL.20200701.20201031.txt

# Processa Umidade Relativa e Vento separadamente.
for arquivo in  RH2M.GFS.ANL.20200701.20201031.nc VENTO10M.GFS.ANL.20200701.20201031.nc 
do
   echo $arquivo
   cdo -s remapbil,$DIR_SHAPE/APA_MorroPedreira_PARNA_SerraCipo.nc $DIR_INPUT/$arquivo $DIR_TMP/tmp01.nc
   # Salva o dado espacial recortado na área de interesse.
   cdo -s ifthen $DIR_SHAPE/APA_MorroPedreira_PARNA_SerraCipo.nc $DIR_TMP/tmp01.nc $DIR_OUTPUT/$arquivo
   cdo -s remapbil,$DIR_SHAPE/PARNA_SerraCipo.nc $DIR_INPUT/$arquivo $DIR_TMP/tmp02.nc
   # Salva a série temporal na área de interesse.
   if [ $arquivo = "RH2M.GFS.ANL.20200701.20201031.nc" ]
   then
      cdo -s -output -fldmean -ifthen $DIR_SHAPE/PARNA_SerraCipo.nc $DIR_TMP/tmp02.nc | sed 's/\./,/g' > $DIR_OUTPUT/serie_temporal_$arquivo.txt
   else
      cdo -s splitvar $DIR_TMP/tmp02.nc $DIR_TMP/tmp02.
      cdo -s -output -fldmean -ifthen $DIR_SHAPE/PARNA_SerraCipo.nc $DIR_TMP/tmp02.u10m.nc | sed 's/\./,/g' > $DIR_OUTPUT/serie_temporal_"$arquivo"_u10m.txt
      cdo -s -output -fldmean -ifthen $DIR_SHAPE/PARNA_SerraCipo.nc $DIR_TMP/tmp02.v10m.nc | sed 's/\./,/g' > $DIR_OUTPUT/serie_temporal_"$arquivo"_v10m.txt
   fi
done

DATA="2020-07-01"  # Data inicial.

# Acumulado mensal de precipitação:
cdo -s -settaxis,$DATA,00:00:00,1mon -monsum $DIR_OUTPUT/PREC.IMERG.20200701.20201031.nc $DIR_OUTPUT/ACUM.MENSAL.PREC.IMERG.20200701.20201031.nc

# Média mensal:
for arquivo in TEMP2M.GFS.ANL.20200701.20201031.nc RH2M.GFS.ANL.20200701.20201031.nc VENTO10M.GFS.ANL.20200701.20201031.nc
do
   cdo -s -settaxis,$DATA,00:00:00,1mon -monmean $DIR_OUTPUT/$arquivo $DIR_OUTPUT/MED.MENSAL.$arquivo
done

# Remove arquivos desnecessários.
rm -f $DIR_TMP/tmp??.nc  $DIR_TMP/eca_???.mes.??.nc $DIR_TMP/mes.??.nc
rm -f $DIR_TMP/serie_temporal_* $DIR_TMP/tmp??.*.nc
rm -f $DIR_OUTPUT/serie_temporal_PREC.IMERG.*.nc