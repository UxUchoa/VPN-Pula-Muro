# GoLiveBypass: instalador "Discord com VPN"

Instalador **não oficial** do [GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), feito pra quem quer **ligar o PC (ou clicar num atalho) e já ter o Discord com Go Live funcionando**: a VPN sobe primeiro e o Discord abre já por ela.

> O GoLiveBypass é do [bezumiya](https://github.com/bezumiya/GoLiveBypass) e é GPLv3. Este repositório **compila a tag oficial sem alterar nada** e empacota com um instalador. Login no Proton, escolha de rota e VPN são exatamente os do app original. Bugs do app vão pras [issues do projeto original](https://github.com/bezumiya/GoLiveBypass/issues). Bugs do instalador vêm [pra cá](https://github.com/UxUchoa/GoLiveBypass-Instalador/issues).

## Download

**[⬇️ Baixar o instalador (última versão)](https://github.com/UxUchoa/GoLiveBypass-Instalador/releases/latest)**: baixe o arquivo `GoLiveBypass-Instalador-x.y.z-rN.exe`.

Você precisa de:
- Windows 10 ou 11 (64 bits)
- Discord instalado
- Uma conta [Proton](https://account.protonvpn.com/signup) (a grátis serve)

## Passo a passo

1. **Dê dois cliques no instalador.** Como ele não tem assinatura digital, o Windows pode mostrar *"O Windows protegeu o computador"*. Clique em **Mais informações → Executar assim mesmo**.
2. **Avance até instalar.** Não pede administrador: instala só pro seu usuário.
3. **O GoLiveBypass abre sozinho.** Nele:
   - entre com a sua conta **Proton**;
   - clique em **Ativar**. Na primeira vez o Windows pede administrador pra instalar o **WireSock**, que é o motor da VPN. Pode aceitar.
4. **Volte pro instalador.** Ele fica esperando na tela *"Entre na sua conta Proton"*. Assim que a VPN liga, aparece a pergunta:
   > **Gostaria que o GoLiveBypass iniciasse antes do Discord quando o Windows ligar?**

   Responda **Sim** (recomendado). Isso marca as duas opções da tela:
   - ☑ **Iniciar com o Windows**: ao ligar o PC, o GoLiveBypass sobe escondido na bandeja, liga a VPN e **só depois** abre o Discord por ela. Você já entra no Discord com o bypass rodando.
   - ☑ **Impedir o Discord de abrir sozinho com o Windows**: assim o Discord nunca abre antes da VPN, porque quem abre ele é o GoLiveBypass.

   Se responder **Não**, o GoLiveBypass não inicia com o Windows. Antes de avançar ainda dá pra marcar ou desmarcar as caixinhas.
5. **Avançar → Concluir.** Pronto.

### No dia a dia

- **Ligou o PC** (com "Iniciar com o Windows" marcado): é só esperar. A VPN sobe e o Discord abre sozinho, pronto pra compartilhar a tela.
- **Quer abrir na mão:** clique no atalho **Discord com VPN**, na área de trabalho ou no Menu Iniciar. Ele liga a VPN e abre o Discord por ela, em uns 30 segundos.
- **Pra fechar:** botão direito no ícone do GoLiveBypass na bandeja → **Sair**.
  ⚠️ **Não use "Desativar"**. Ele desliga a VPN de vez, e aí o atalho e a inicialização só abrem o app sem ligar a VPN. Se fizer isso sem querer, abra o **GoLiveBypass (configurar)** e clique em **Ativar** de novo.
- **Mudar conta, rota ou configurações:** Menu Iniciar → **GoLiveBypass (configurar)**.

### Pulei as opções no instalador. E agora?

Rode o instalador de novo. Ele reinstala por cima sem perder o login, e na tela do Proton as caixinhas valem como estado final: marcar liga, desmarcar desliga.

⚠️ **Não use "Iniciar com Windows" da bandeja do GoLiveBypass.** O instalador já cuida da inicialização por outro caminho (veja abaixo), e ligar as duas coisas abre o app duas vezes no boot.

Se quiser garantir que o Discord nunca abra antes da VPN, no Discord vá em Configurações → **Configurações do Windows** e desligue **Abrir o Discord**. Assim ele não recria a entrada de inicialização dele.

## Como funciona

- Só o **Discord** passa pela VPN (WireGuard da ProtonVPN, via WireSock). Jogos, navegador e o resto do PC continuam na sua internet normal.
- O atalho e a inicialização rodam `GoLiveBypass.exe --hidden`, um recurso do próprio app: ele sobe só na bandeja e, se da última vez a VPN tava ativa, usa a sua sessão Proton salva, liga o túnel e só depois reabre o Discord por ele.
- O app se atualiza sozinho pelas releases oficiais do bezumiya/GoLiveBypass.

| O que o instalador mexe | Onde |
| --- | --- |
| App | `%LOCALAPPDATA%\Programs\GoLiveBypass\GoLiveBypass.exe` |
| Atalho **Discord com VPN** (`--hidden`) | Área de trabalho e Menu Iniciar |
| Atalho **GoLiveBypass (configurar)** | Menu Iniciar (e área de trabalho, se marcar) |
| Iniciar com o Windows (opcional) | Tarefa **GoLiveBypass - VPN antes do Discord** no Agendador de Tarefas: no logon, espera 10 s e roda `GoLiveBypass.exe --hidden` **como administrador** ("privilégios mais altos"), com prioridade normal e sem limite de tempo. Criar essa tarefa pede um "Sim" do Windows na instalação. Uma entrada antiga `HKCU\...\Run\GoLiveBypass` é removida pra não abrir duas vezes |
| Bloquear o Discord na inicialização (opcional) | Apaga a entrada `Discord` de `HKCU\...\Run` (guardada pra desinstalação devolver) e desliga o interruptor do Discord em Aplicativos → Inicialização (`StartupApproved\Run`) |

**Por que uma tarefa e não a chave `Run`?** Num PC de teste o Windows pulou a entrada `Run` do GoLiveBypass no boot, sem erro nenhum no log, e ainda abriu o Discord com o interruptor dele desligado. Resultado: o Discord subia sem VPN, sem tela e sem câmera. A tarefa de logon não depende dessa lista e deixa histórico no Agendador (aba Histórico) pra conferir se rodou. O `--hidden` vai dentro do XML da tarefa, não numa linha de comando, porque o projeto original já teve um `reg add ... --hidden` barrado pelo Defender.

**Por que como administrador?** O GoLiveBypass pede permissão de administrador ao Windows toda vez que liga a VPN (pra subir o WireSock), e pula esse pedido quando já roda como administrador. No boot, aberto em segundo plano, o pedido ficava piscando na barra de tarefas e a ativação desistia depois de 2 minutos, sem VPN e sem Discord. Com a tarefa elevada, não aparece pedido nenhum no boot: nos testes, a VPN subiu ~11 s depois do app abrir e o Discord ~5 s depois da VPN.

Efeito colateral: o Discord é aberto pelo GoLiveBypass, então **também roda como administrador**. Na prática, arrastar arquivo do Explorer pra dentro do Discord para de funcionar (anexar pelo clipe continua normal). Se não quiser isso, recuse o "Sim" na instalação: a inicialização continua, mas o Windows vai pedir confirmação a cada boot.

## Desinstalar

Configurações do Windows → Aplicativos → **GoLiveBypass (Discord com VPN)** → Desinstalar.

Isso remove o app, os atalhos e a tarefa de inicialização (o Windows pede um "Sim" pra apagar a tarefa de administrador), e **devolve o Discord pra iniciar sozinho** (a entrada dele e o interruptor) se foi o instalador que bloqueou. O login do Proton e as configurações ficam em `%LOCALAPPDATA%\GoLiveBypass`. Apague essa pasta se quiser limpar tudo. O WireSock fica como programa separado em Aplicativos.

## Instalação silenciosa (pra quem manja)

```powershell
GoLiveBypass-Instalador-2.0.16-r4.exe /VERYSILENT /INICIAR=1 /BLOQUEARDISCORD=1
```

`/INICIAR=1` cria a tarefa de inicialização com o Windows e `/BLOQUEARDISCORD=1` bloqueia o autostart do Discord. O login no Proton continua sendo feito no app. Se o GoLiveBypass estiver aberto, o instalador silencioso sai com código 1 sem mexer em nada.

## Compilar você mesmo

Precisa de Git, Node.js 24+, Go 1.26+ e [Inno Setup 6](https://jrsoftware.org/isinfo.php).

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.16 -Rev 4
```

O script clona a tag `v2.0.16` do repositório oficial, roda `npm ci` e `npm run build:win` (o mesmo build do projeto) e gera `dist\GoLiveBypass-Instalador-2.0.16-r4.exe` com o `.sha256` ao lado.

## Versões

O nome do instalador é `GoLiveBypass-Instalador-<versão do app>-r<revisão do instalador>.exe`. A revisão muda quando o instalador muda, mesmo com o app igual.

Pra saber qual está num PC: **Configurações → Aplicativos** mostra `GoLiveBypass (Discord com VPN) rN` e a versão `2.0.16-rN`. Ou rode `reg query HKCU\Software\GoLiveBypass-Instalador /v Versao`. A r1 não grava esse valor.

| Revisão | Data | App | O que mudou |
|---|---|---|---|
| **r4** | 13/11/2026 | 2.0.16 | Corrige o furo da r3: a janela do app, aberta pelo instalador, media as rotas de novo e desfazia a rota fixa, e o aviso do Firewall voltava. Agora a rota é fixada antes de abrir a janela, e o instalador espera a medição terminar antes de fixar. |
| r3 | 11/11/2026 | 2.0.16 | Fixa a rota medida na primeira ativação. O boot deixa de medir as rotas de novo, e o Firewall para de perguntar sobre `golive-speed-probe.exe` a cada boot. |
| r2 | 08/11/2026 | 2.0.16 | Inicialização por tarefa agendada (pede administrador uma vez) no lugar da entrada no registro, que o Windows às vezes pulava. |
| r1 | 06/11/2026 | 2.0.16 | Primeira versão (publicada no GitHub): atalho "Discord com VPN", inicialização pela chave Run e bloqueio do autostart do Discord. |

## Licença

GPLv3, a mesma do projeto original (veja [LICENSE](LICENSE)). O código-fonte do app é o da tag oficial correspondente em [bezumiya/GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), e cada release daqui também traz o zip do código-fonte usado no build.
