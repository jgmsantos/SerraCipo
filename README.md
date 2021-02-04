# SerraCipo

Sugestões:
1) Período de análise: julho a outubro de 2020;
2) Usar as variáveis: vento (direção e velocidade), precipitação e temperatura do ar nas escalas diária e mensal;
3) Número de dias consecutivos sem chuva, R<=1mm/dia;
4) Categorias de velocidade do vento: https://library.wmo.int/doc_num.php?explnum_id=3177
5) Linha de comando exemplo: =SE(B3<=20;1;SE(E(B3>20;B3<=40);2;SE(E(B3>40;B3<=60);3;SE(E(B3>60;B3<=80);4;SE(E(B3>80;B3<=100);5)))))
