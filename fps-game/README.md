# Operação Fênix — protótipo FPS 3D

Protótipo inicial de tiro em primeira pessoa feito em Godot 4, com cenário militar criado por geometria 3D, movimentação, arma em primeira pessoa, disparo por raycast, recarga, áudio de tiro/reload gerado em tempo de execução, inimigos que perseguem e atacam, vida, munição e objetivo da missão.

## Como abrir e jogar
1. Instale o Godot Engine 4.3 ou superior.
2. Importe a pasta `fps-game` pelo arquivo `project.godot`.
3. Execute o projeto (F6/F5).
4. WASD movimenta, Shift corre, mouse mira, clique esquerdo dispara, R recarrega, Esc libera o mouse. Enter reinicia após derrota.

## Estado do projeto
Esta é uma primeira versão jogável de protótipo: cenário e modelos provisórios são criados pelo código, não são assets AAA. O som é sintetizado no próprio jogo. Os controles touchscreen básicos estão iniciados, mas precisam de uma etapa dedicada de interface mobile e testes em aparelho.

## Exportação
Para gerar APK/IPA, é necessário configurar templates de exportação Godot e, para iOS, assinatura Apple para instalar num aparelho. Um IPA sem assinatura pode ser empacotado para testes técnicos, mas não pode ser instalado normalmente no iPhone.
