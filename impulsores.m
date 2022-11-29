function acuracia=impulsores;
% Treinamento e teste de uma RNA para reconhecimento de padrões (defeitos) 
% de imagens de impulsores de bombas submersas fabricados por fundição.
% No problema específico temos 99 imagens de cada: impulsores em bom estado 
%(ok) e deifeituosos (def).
% Cada imagem tem tamanho 512 x 512 pixels(RGB).
% As imagens 01 a 70 de cada caso serão utilizadas como treinamento.
% As imagens de 71 a 99 de cada caso serão utilizadas no teste.
% Sintaxe: [X,Y]=impulsores.
% A rede treinada é salva no arquivo REDEIMP.MAT.
% =========================================================================
close all                      % Fecha figuras abertas
clc                            % Limpa a tela
rand('seed',10);               % Garante repetibilidade do experimento
randn('seed',10);              % Garante repetibilidade do experimento
% =========================================================================
NumImg=99;                     % Numero total de imagens para cada estado de impulsor
Nimg=70;                       % Define numero de imagens usadas no treinamento (por estado do impulsor)
Ntest=NumImg-Nimg;             % Resto = quantidade de imagens usadas para validação da RNA
C=8;                           % Tamanho do vetor de entrada (condensação)

% Monta vetores de entrada/saida da RNA
Y=[];                            % Inicializa vetor de saida
X=[];                            % Inicializa vetor de entrada
[X,Y]=le_imagem(X,Y,1,Nimg,1);  % Le histograma das imagens de impulsores sem defeito (1=Ok) - usa R, descarta GB;   
[X,Y]=le_imagem(X,Y,1,Nimg,0);  % Le histograma das imagens de impulsores com defeito (0=def) - usa R, descarta GB;     
mostra_imagem(X,Nimg,1,1,'Resultado obtido');

% Com o "histograma", dimensão de informação de cada imagem reduziu para 512 pixels.
% Deseja-se reduzir ainda mais condensando as colunas de pixels em grupos de tamanhos C.
X=condensa_dados(X,C);
mostra_imagem(X,Nimg,1,1, 'Resultado médio por area definida');

% Criação da RNA
Qte_neuron = 50;           
net=feedforwardnet(Qte_neuron);  % Cria rede

% Parametros para o treinamento da RNA
net.trainParam.epochs = 500;
net.trainParam.goal = 1e-15;

% Treinamento da RNA
net_treinada = train(net,X,Y);
save redeimp net_treinada     % Salva arquivo com a rede treinada
disp('Rede Treinada, salva no arquivo "redeimp.mat"')
disp('    ')
disp('Tecle <ENTER>  para continuar')
pause

% Validação da rede (imagens ineditas)
Y=[];                          % Inicializa vetor de saida
X=[];                          % Inicializa vetor de entrada

[X,Y]=le_imagem(X,Y,Nimg+1,Nimg+Ntest,1);  % Le histograma das imagens de impulsores sem defeito (1=Ok) - usa R, descarta GB;   
[X,Y]=le_imagem(X,Y,Nimg+1,Nimg+Ntest,0);  % Le histograma das imagens de impulsores comm defeito (0=def) - usa R, descarta GB;     
X=condensa_dados(X,C);         % Condensa dados do histograma

Yn = sim(net_treinada,X);      % Simula a rede trainada com novos dados para validação
Yn=um_e_zero(Yn);              % Troca valores numéricos arredondados por UM e ZERO, onde UM indica a posição do maximo

erro=Y-Yn;
disp('Erro:');
disp(erro);
qtdacertos=0;
for i=1:length(erro(1,:))
    if erro(1,i)==0
        qtdacertos=qtdacertos+1;
    end
end
disp('Quantidade de acertos:');
disp(qtdacertos);
disp('Quantidade de erros:');
disp(length(erro(1,:))-qtdacertos);
disp('Acuracia da classificacao:');
acuracia=qtdacertos/length(erro(1,:));

%==========================================================================
%==========================================================================
%==========================================================================
function [X,Y]=le_imagem(X,Y,xIni,xFim,tipo);
for i=xIni:xFim                % Varre as n-imagens do tipo selecionado
    nomearq=completa_nome(tipo,i);
    A=imread(nomearq);         % Carrega matriz RGB associada a imagem
    A=A(:,:,1);                % Descarta informações de G e B
    A=sum(A);                  % Soma dados de coluna para gerar informação tipo histograma
    A=A/max(A);                % Normaliza
    proximo=size(X,2)+1;       % Indica coluna onde serao inseridos os novos dados
    X(:,proximo)=A';           % Guarda dados de de entrada

    % Guarda respectivos dados de saida
    if tipo == 1 
        Y(:,proximo)=[1 0];
    elseif tipo == 0 
        Y(:,proximo)=[0 1];
    end
end
%==========================================================================
function nomearq=completa_nome(tipo,i);
    if tipo == 1
        tiponome='ok';
    elseif tipo == 0 
        tiponome='def';
    end
    if i<10 I=strcat('0',num2str(i));
    else I=num2str(i);
    end
    nomearq=strcat('cast_',tiponome,'_0_(',I,').jpeg');
%==========================================================================
function mostra_imagem(X,Nimg,limpa,pausa,titulo);
% Para visualizar dados do vetor de entrada X
if limpa
   close all
end
hold on
grid on
title(titulo)
plot(X(:,1:Nimg),'g')
plot(X(:,Nimg+1:2*Nimg),'r')
if pausa
    xlabel('Tecle <ENTER> para continuar')
    pause
    xlabel(' ')
end
%==========================================================================
function X=condensa_dados(x,npartes);
X=[];
passo=floor(size(x,1)/npartes);
for col=1:size(x,2)                  % Para cada vetor de dados de entrada (coluna)
    for n=1:npartes                  % Dividindo o vetor em n partes
        soma=0;
        for i=(n-1)*passo+1:n*passo    % Calculando a média para cada parte
            soma=soma+x(i,col);
        end
            X(n,col)=soma/passo;           % Atualiza vetor X com a média do trecho
    end
end
%==========================================================================
function Yn=um_e_zero(Yn);
m=max(Yn);                           % Indica maximos de cada coluna de dados
for j=1:size(Yn,2)                   % Varre cada coluna
   Yn(:,j)=Yn(:,j)==m(j);            % Troca valores reais pelos numeros inteiros 1 e 0, 1 indica a posicao do maximo
end
%==========================================================================
