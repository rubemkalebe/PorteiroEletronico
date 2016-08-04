	; *********************************************************************************************************
	; *********************************** PORTEIRO ELETRÔNICO EM ASSEMBLY *************************************
	; *********************************************************************************************************
	; * Este programa descreve o funcionamento de um Porteiro Eletrônico a ser implementado em um Arduino UNO *
	; * R3. A linguagem utilizada neste programa é AVR Assembly, desenvolvido especificamente para a arquite- *
	; * tura do microcontrolador ATmega328.								          *
	; * O programa obedece as especificações descritas no relatório e a pinagem utilizada foi a seguinte:     *
	; *    Sensor 1 (Sensor para detectar entrada) -> Digital Pin 2;                                          *
	; *    Sensor 2 (Sensor para detectar saída)   -> Digital Pin 4;					  *
	; *    Botão para ver log		       -> Digital Pin 7;					  *
	; *    Botão para solicitar saída	       -> Digital Pin 8;					  *
	; *    Buzzer				       -> Digital Pin 12;					  *
	; * As informações serão trocadas através da comunicação serial da placa, ou seja, a senha será enviada   *
	; * pela entrada serial e o log será visualizado pela saída serial.					  *
	; *********************************************************************************************************
	; *********************************************************************************************************

.include "m328def.inc"						;Inclusao de arquivo contendo definicoes do ATmega328

;Definicao de registradores necessarios
.def tmp1 = R16
.def tmp2 = R17
.def tmp3 = R18
.def buzzer = R19
.def d0 = R20
.def entradas = R21
.def saidas = R22

.equ OneSecond = 16 * 1000000 / 5 				;Macro que define 1 segundo

SETUP:
	;Inicializa o ponteiro da pilha (necessario por causa das sub-rotinas)
	ldi  tmp1,high(RAMEND)
	out  SPH,tmp1
	ldi  tmp1,low(RAMEND)
	out  SPL,tmp1

	;Configura porta serial na velocidade de 9600bps
	ldi tmp1,0x67
	sts UBRR0L,tmp1
	ldi tmp1,0x00
	sts UBRR0H,tmp1

	;Liga os modulos transmissor e receptor da porta serial
	ldi tmp1, (1<<TXEN0)|(1 << RXEN0)
	sts UCSR0B, tmp1

	;Configura porta serial para 8bits, 8N1 
	ldi tmp1, (1<<UCSZ01)|(1<<UCSZ00)
	sts UCSR0C, tmp1

	;Configuracao de portas como saida
	ldi tmp1, 0b00010000 ; Setagem de pins
	out DDRB, tmp1
	;Configura pinos como saida e inicializa com '0'
	ldi buzzer, 0x00
	out PORTB, buzzer

	;Configuracao de porta como entrada
	;Configura pinos como entrada e ativa pull-up
	cbi DDRD, 2
	sbi PORTD, 2
	cbi DDRD, 4
	sbi PORTD, 4
	cbi DDRD, 7
	sbi PORTD, 7
	cbi DDRB, 0
	sbi PORTB, 0

MAIN:
	ldi tmp1, 0xFF
	ldi ZH,HIGH(ERRO1<<1)
	ldi ZL,LOW(ERRO1<<1)
L1A:
	lpm tmp1,Z
	cpi tmp1,0
	breq MAINA
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	sts UDR0,tmp1
	inc ZL
	rjmp L1A
MAINA:
	in tmp1, PIND 		;Le o estado do sensor 1
	bst tmp1, 2		;Grava o bit no registrador
	brts ENTRADA		;Caso o bit esteja setado, verifica se a situacao eh de entrada
	rjmp SAIDA		;Senao, deve ser saida

ENTRADA:
	sbi  PortB, 4		;Liga o buzzer
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	cbi  PortB, 4		;Desliga o buzzer
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	sbi  PortB, 4		;Liga o buzzer
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	cbi  PortB, 4		;Desliga o buzzer
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	rcall DELAY20
	in tmp2, PIND 		;Le o estado do sensor 1
	bst tmp2, 4		;Grava o bit no registrador
	brtc SENHA1		;Caso o bit nao esteja setado, a situacao eh de entrada e o sistema pede a senha
	rjmp SIT_INVALIDA	;Senao, esta seria uma situacao invalida

SIT_INVALIDA:
	ldi tmp1, 0xFF
	ldi ZH,HIGH(ERRO1<<1)
	ldi ZL,LOW(ERRO1<<1)
L1:
	lpm tmp1,Z
	cpi tmp1,0
	breq MAIN
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	sts UDR0,tmp1
	inc ZL
	rjmp L1

ALERTA:
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	cbi  PortB, 4			; desliga o buzzer
	rcall DELAY200
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	cbi  PortB, 4			; desliga o buzzer
	rcall DELAY200
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	rjmp SENHA1

SENHA1:
	ldi tmp1, 0xFF
	ldi ZH,HIGH(REQUEST<<1)
	ldi ZL,LOW(REQUEST<<1)
L2:
	lpm tmp1,Z
	cpi tmp1,0
	breq SENHA2
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	sts UDR0,tmp1
	inc ZL
	rjmp L2

SENHA2:
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	
	;Verifica se alguem passou pelo sensor 1
	in tmp1, PIND 		;Le o estado do sensor 1
	bst tmp1, 4		;Grava o bit no registrador
	brts JUMP_MAIN		;Caso o bit esteja setado, volta pro inicio

	;Verifica se alguem passou pelo sensor 2
	in tmp1, PIND 		;Le o estado do sensor 2
	bst tmp1, 4		;Grava o bit no registrador
	brts ALERTA		;Caso o bit esteja setado, emite um alerta sonoro

	;Verifica se tem algo na porta serial, atraves do bit RXC0 do registrador UCSR0A. Se nao tiver, volta para o inicio do loop
	lds r0, UCSR0A
	sbrs r0, RXC0
	rjmp SENHA2

	;Armazena o caracter recebido em tmp1
	lds tmp1,UDR0	

	;Transmite um asterisco, indicando que o caractere foi recebido e ao mesmo tempo, escodendo a senha
	ldi tmp2,0x2a
	sts UDR0,tmp2
	cpi tmp1,'1'      	
	brne SENHA_ERRADA
	rjmp SENHA3			;Caso o caractere estiver certo, continua recebendo a senha

SENHA_ERRADA:
	ldi tmp1, 0xFF
	ldi ZH,HIGH(ERRO2<<1)
	ldi ZL,LOW(ERRO2<<1)
L3:
	lpm tmp1,Z
	cpi tmp1,0
	breq ALERTA
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	sts UDR0,tmp1
	inc ZL
	rjmp L3

SENHA3:
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20

	;Verifica se alguem passou pelo sensor 1
	in tmp1, PIND 		;Le o estado do sensor 1
	bst tmp1, 4		;Grava o bit no registrador
	brts JUMP_MAIN		;Caso o bit esteja setado, volta pro inicio

	;Verifica se alguem passou pelo sensor 2
	in tmp1, PIND 		;Le o estado do sensor 2
	bst tmp1, 4		;Grava o bit no registrador
	brts ALERTA		;Caso o bit esteja setado, emite um alerta sonoro

	;Verifica se tem algo na porta serial, atraves do bit RXC0 do registrador UCSR0A. Se nao tiver, volta para o inicio do loop
	lds r0, UCSR0A
	sbrs r0, RXC0
	rjmp SENHA3

	;Armazena o caracter recebido em tmp1
	lds tmp1,UDR0	

	;Transmite um asterisco, indicando que o caractere foi recebido e ao mesmo tempo, escodendo a senha
	ldi tmp2,0x2a
	sts UDR0,tmp2
	cpi tmp1,'2'
	brne SENHA_ERRADA
	rjmp SENHA4			;Caso o caractere estiver certo, continua recebendo a senha

ALERTA2:
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	cbi  PortB, 4			; desliga o buzzer
	rcall DELAY200
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	cbi  PortB, 4			; desliga o buzzer
	rcall DELAY200
	sbi  PortB, 4			; liga o buzzer
	rcall DELAY200
	rjmp SENHA1

JUMP_MAIN: rjmp MAIN

SENHA4:
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20

	;Verifica se alguem passou pelo sensor 1
	in tmp1, PIND 		;Le o estado do sensor 1
	bst tmp1, 4		;Grava o bit no registrador
	brts JUMP_MAIN		;Caso o bit esteja setado, volta pro inicio

	;Verifica se alguem passou pelo sensor 2
	in tmp1, PIND 		;Le o estado do sensor 2
	bst tmp1, 4		;Grava o bit no registrador
	brts ALERTA2		;Caso o bit esteja setado, emite um alerta sonoro

	;Verifica se tem algo na porta serial, atraves do bit RXC0 do registrador UCSR0A. Se nao tiver, volta para o inicio do loop
	lds r0, UCSR0A
	sbrs r0, RXC0
	rjmp SENHA4

	;Armazena o caracter recebido em tmp1
	lds tmp1,UDR0	

	;Transmite um asterisco, indicando que o caractere foi recebido e ao mesmo tempo, escodendo a senha
	ldi tmp2,0x2a
	sts UDR0,tmp2
	cpi tmp1,'3'
	brne SENHA_ERRADA
	rjmp SENHA5			;Caso o caractere estiver certo, continua recebendo a senha

SENHA_ERRADA2:
	ldi tmp1, 0xFF
	ldi ZH,HIGH(ERRO2<<1)
	ldi ZL,LOW(ERRO2<<1)
L4:
	lpm tmp1,Z
	cpi tmp1,0
	breq ALERTA2
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20
	sts UDR0,tmp1
	inc ZL
	rjmp L4

SENHA5:
	;Espera 20ms (para dar tempo da tranmissao ocorrer)
	rcall DELAY20

	;Verifica se alguem passou pelo sensor 1
	in tmp1, PIND 		;Le o estado do sensor 1
	bst tmp1, 4		;Grava o bit no registrador
	brts JUMP_MAIN		;Caso o bit esteja setado, volta pro inicio

	;Verifica se alguem passou pelo sensor 2
	in tmp1, PIND 		;Le o estado do sensor 2
	bst tmp1, 4		;Grava o bit no registrador
	brts ALERTA2		;Caso o bit esteja setado, emite um alerta sonoro

	;Verifica se tem algo na porta serial, atraves do bit RXC0 do registrador UCSR0A. Se nao tiver, volta para o inicio do loop
	lds r0, UCSR0A
	sbrs r0, RXC0
	rjmp SENHA5

	;Armazena o caracter recebido em tmp1
	lds tmp1,UDR0

	;Transmite um asterisco, indicando que o caractere foi recebido e ao mesmo tempo, escodendo a senha
	ldi tmp2,0x2a
	sts UDR0,tmp2
	cpi tmp1,'4'
	brne SENHA_ERRADA2
	rjmp MAIN		;Se tudo ocorrer certo, volta para o inicio

SAIDA:


;Sub-rotina que espera 20ms
DELAY20:
	ldi  tmp3, byte3 (OneSecond / 50)
	ldi  tmp2, high (OneSecond / 50)
	ldi  tmp1, low  (OneSecond / 50)

	subi tmp1, 1
	sbci tmp2, 0
	sbci tmp3, 0
	brcc pc-3
	ret

;Sub-rotina que espera 200ms
DELAY200:
	ldi  tmp3, byte3 (OneSecond / 5)
	ldi  tmp2, high (OneSecond / 5)
	ldi  tmp1, low  (OneSecond / 5)

	subi tmp1, 1
	sbci tmp2, 0
	sbci tmp3, 0
	brcc pc-3
	ret

.org 0x000							;Grava dentro da ROM comecando no 0
MSG: .db "BEM-VINDO!", 0x0a, 0
.org 0x500
ERRO1: .db "SITUACAO INVALIDA!", 0x0a, 0
.org 0x519
ERRO2: .db "SENHA ERRADA!", 0x0a, 0
.org 0x533
REQUEST: .db "DIGITE A SENHA: ", 0
.org 0x549

