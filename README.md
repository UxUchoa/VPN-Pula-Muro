<p align="center">
  <img src="assets/caramelo.png" width="128" alt="Caramelo, o mascote da VPN Pula Muro" />
</p>

<h1 align="center">VPN Pula Muro</h1>

<p align="center">
  <b>Liga o PC e o Discord já abre com Go Live e câmera funcionando.</b><br/>
  A VPN sobe primeiro e o Discord abre já por ela. Sem abrir nada na mão.
</p>

<p align="center">
  <a href="https://github.com/UxUchoa/VPN-Pula-Muro/releases/latest"><b>⬇️ Baixar a última versão</b></a>
  ·
  <a href="https://github.com/UxUchoa/VPN-Pula-Muro/issues">🐛 Reportar bug</a>
</p>

---

## 🐶 O que é isso

A VPN Pula Muro é um **fork do [GoLiveBypass](https://github.com/bezumiya/GoLiveBypass)**.

O GoLiveBypass resolve o problema de verdade: passa só o Discord por uma VPN da Proton e devolve o Go Live e a câmera pra quem tá no Brasil. Mas no dia a dia era preciso abrir o bypass, ligar a VPN e só depois abrir o Discord, todo santo dia. Aí eu peguei a versão original e fiz **melhorias de qualidade de vida** pra isso sumir: **você liga o PC e já entra no Discord com a VPN ligada**, sem clicar em nada.

Toda a parte que faz a mágica (login na Proton, escolha de rota e VPN por aplicativo) é do projeto original, do [bezumiya](https://github.com/bezumiya) e de [muita gente](https://github.com/bezumiya/GoLiveBypass#agradecimentos). Valeu demais, galera do GoLiveBypass! 🙏

## ✨ O que eu melhorei

### 🚀 Liga o PC e tá pronto
- **Inicia junto com o Windows na ordem certa:** primeiro a VPN, depois o Discord, já passando por ela. Você entra no Discord pronto pra compartilhar a tela.
- **O Discord não abre antes da VPN:** o instalador desliga o autostart do Discord e quem abre ele é a VPN Pula Muro (opcional, e o desinstalador devolve).
- **Atalho "Discord com VPN":** um clique liga a VPN e abre o Discord por ela.
- **Sem perguntas no boot:** a inicialização roda como tarefa agendada com permissão de administrador, então o Windows pede "Sim" **uma vez** na instalação e nunca mais no boot.

### 🎯 Melhor rota, sem ficar medindo
- **Fixa a melhor rota** escolhida na primeira ativação. O boot vai direto pra ela, em vez de medir todas as rotas de novo.
- **Some o aviso do Firewall** sobre o `golive-speed-probe.exe` que aparecia a cada boot.

### 📦 Instalador de verdade
- Dois cliques e pronto: instala, abre o app pra você entrar na Proton e **pergunta se é pra iniciar antes do Discord**.
- Atualiza por cima sem perder o login, e desinstala limpando tudo.
- Atualização automática pelas releases deste repositório.

### 🛠️ Correções
- **Login da Proton de volta:** a versão 2.0.16 passou a ser recusada pela Proton (erro 5003). A VPN Pula Muro já vem com a 2.0.19.
- **Helper do Proton sumindo:** abrir o app de novo com ele já rodando apagava os arquivos dele (e aí "o componente Proton não foi encontrado"). Agora cada abertura usa uma pasta própria.

### 🎨 Com a nossa cara
- **Verde e amarelo** e o **caramelo** no logo, no ícone e na bandeja.
- **Bug? Issue aqui:** o botão de bug salva um diagnóstico sem senha nem token e abre uma issue neste repositório.

## 🔍 Original x VPN Pula Muro

| | GoLiveBypass original | VPN Pula Muro |
|---|---|---|
| Nome e visual | GoLiveBypass | **VPN Pula Muro**, verde e amarelo, com o caramelo |
| Instalação | `.exe` portátil, você abre na mão | **Instalador** com atalho "Discord com VPN" e menu Iniciar |
| Iniciar com o Windows | Entrada no registro (às vezes o Windows pula) | **Tarefa agendada**: a VPN sobe antes e o Discord abre por ela |
| Discord abrindo antes da VPN | Pode acontecer | O instalador **bloqueia o autostart do Discord** (opcional) |
| Rota no boot | Mede todas de novo a cada boot (o Firewall pergunta do `golive-speed-probe.exe`) | **Fixa a melhor rota** da primeira ativação |
| Abrir o exe com o app já rodando | Apagava os arquivos do app em uso (o helper do Proton sumia) | Cada abertura extrai numa pasta própria |
| Reportar bug | Servidor do projeto original | Abre uma **issue aqui**, com o arquivo de diagnóstico |
| Atualizações | Releases do bezumiya | **Releases deste repositório** |
| Comunidade | Discord do projeto original | Issues deste repositório |

Todas as mudanças no código do app estão em um patch só, [`edicao/uxuchoa.patch`](edicao/uxuchoa.patch), aplicado sobre a tag oficial. Dá pra conferir linha por linha.

## 📋 O que você precisa

- Windows 10 ou 11 (64 bits)
- Discord instalado
- Uma conta [Proton](https://account.protonvpn.com/signup) (a grátis serve)

## 💾 Instalando

1. Baixe o **`VPN-Pula-Muro-Instalador-x.y.z-rN.exe`** na [última release](https://github.com/UxUchoa/VPN-Pula-Muro/releases/latest) e dê dois cliques.
   O instalador não tem assinatura digital, então o Windows pode mostrar *"O Windows protegeu o computador"*. Clique em **Mais informações → Executar assim mesmo**.
2. Avance até instalar. Instala só pro seu usuário, sem pedir administrador.
3. **A VPN Pula Muro abre sozinha.** Nela:
   - entre com a sua conta **Proton**;
   - espere ela medir a melhor rota (1 a 3 minutos). Na primeira vez o **Firewall do Windows** pode perguntar sobre `golive-speed-probe.exe`: clique em **Permitir**;
   - clique em **Ativar**. Na primeira vez o Windows pede administrador pra instalar o **WireSock**, o motor da VPN.
4. **Volte pro instalador.** Quando a VPN liga, ele pergunta:
   > **Gostaria que a VPN Pula Muro iniciasse antes do Discord quando o Windows ligar?**

   Responda **Sim**. O Windows pede administrador **uma vez** pra criar a inicialização. As duas opções da tela ficam marcadas:
   - ☑ **Iniciar com o Windows**: a VPN Pula Muro sobe escondida na bandeja, liga a VPN e **só depois** abre o Discord.
   - ☑ **Impedir o Discord de abrir sozinho**: assim ele nunca abre antes da VPN.
5. **Avançar → Concluir.** Pronto. 🐶

> Já tinha o instalador antigo (GoLiveBypass r1–r4)? É só rodar o novo por cima. Ele atualiza no mesmo lugar e mantém o seu login.

## 🗓️ No dia a dia

- **Ligou o PC:** espere uns 30 segundos. A VPN sobe e o Discord abre sozinho, pronto pra compartilhar a tela.
- **Quer abrir na mão:** clique em **Discord com VPN** na área de trabalho ou no menu Iniciar.
- **Pra fechar:** botão direito no ícone do caramelo na bandeja → **Sair**.
  ⚠️ **Não use "Desativar".** Ele desliga a VPN de vez, e no próximo boot o Discord não abre. Se fizer sem querer, abra a **VPN Pula Muro (configurar)** e clique em **Ativar**.
- **Trocar conta, rota ou configurações:** menu Iniciar → **VPN Pula Muro (configurar)**. Otimizou a rota na janela? Rode o instalador de novo pra fixar a rota nova.

## ⚙️ Como funciona

- Só o **Discord** passa pela VPN (WireGuard da ProtonVPN, via WireSock). Jogos, navegador e o resto do PC continuam na sua internet normal.
- A inicialização é a tarefa **GoLiveBypass - VPN antes do Discord** no Agendador de Tarefas. No logon ela espera 10 s e roda o app com `--hidden`, que sobe na bandeja, usa a sua sessão Proton salva, liga o túnel e só então abre o Discord.
- A tarefa roda como administrador porque o app pede administrador toda vez que liga a VPN. No boot, esse pedido ficava escondido e a ativação desistia. Efeito colateral: o Discord aberto por ela também roda como administrador, e arrastar arquivo do Explorer pra dentro do Discord para de funcionar (anexar pelo clipe continua normal).
- Por compatibilidade, alguns nomes internos continuam do projeto original: o arquivo `GoLiveBypass.exe`, a pasta de dados `%LOCALAPPDATA%\GoLiveBypass` e o nome da tarefa. É isso que permite atualizar sem perder o login.

| O que o instalador mexe | Onde |
|---|---|
| App | `%LOCALAPPDATA%\Programs\VPN Pula Muro\GoLiveBypass.exe` (quem veio do instalador antigo continua em `...\Programs\GoLiveBypass`) |
| Atalhos | **Discord com VPN** e **VPN Pula Muro (configurar)** |
| Iniciar com o Windows | Tarefa agendada **GoLiveBypass - VPN antes do Discord** |
| Bloquear o Discord no boot | Entrada `Discord` de `HKCU\...\Run` (guardada pra devolver) e o interruptor em Aplicativos → Inicialização |
| Rota fixa | `protonRoutePreference: "manual"` em `%LOCALAPPDATA%\GoLiveBypass\settings.json` (com cópia de segurança) |

## ⚠️ Problemas conhecidos

- **"O Windows protegeu o computador"**: o instalador não tem assinatura digital. Use **Mais informações → Executar assim mesmo**.
- **Microsoft Defender acusando `Trojan:Win32/Commando`** na linha `GoLiveBypass.exe --hidden`: é falso positivo, já conhecido no projeto original.
- **Proton recusando o login com código 5003**: era a versão 2.0.16, que o Proton deixou de aceitar em 19/11/2026. A partir da 2.0.19 (instalador r5) isso tá resolvido.

## 🐛 Achou bug?

Clique no botão de bug no canto da janela da VPN Pula Muro. Ele salva um **arquivo de diagnóstico** na pasta Downloads (sem senha, token nem proxy) e abre uma [issue aqui](https://github.com/UxUchoa/VPN-Pula-Muro/issues) já preenchida. É só arrastar o arquivo pra dentro da issue e enviar.

Por favor, **não abra issue no projeto original** sobre a VPN Pula Muro. Os bugs desta versão são tratados aqui.

## 🧹 Desinstalar

Configurações do Windows → Aplicativos → **VPN Pula Muro (Discord com VPN)** → Desinstalar.

Isso remove o app, os atalhos e a inicialização, e **devolve o Discord pra iniciar sozinho** se foi o instalador que bloqueou. O login do Proton fica em `%LOCALAPPDATA%\GoLiveBypass`: apague essa pasta se quiser limpar tudo. O WireSock fica como programa separado em Aplicativos.

## 🤫 Instalação silenciosa

```powershell
VPN-Pula-Muro-Instalador-2.0.19-r5.exe /VERYSILENT /INICIAR=1 /BLOQUEARDISCORD=1
```

`/INICIAR=1` cria a inicialização com o Windows, e `/BLOQUEARDISCORD=1` bloqueia o autostart do Discord. O login no Proton continua sendo feito no app. Se a VPN Pula Muro estiver aberta, o instalador silencioso sai com código 1 sem mexer em nada.

## 🔨 Compilar você mesmo

Precisa de Git, Node.js 24+, Go 1.26+ e [Inno Setup 6](https://jrsoftware.org/isinfo.php).

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.19 -Rev 5
```

O script clona a tag `v2.0.19` do [GoLiveBypass original](https://github.com/bezumiya/GoLiveBypass), aplica o [`edicao/uxuchoa.patch`](edicao/uxuchoa.patch), roda `npm ci` e `npm run build:win` (o mesmo build do projeto) e gera em `dist\`:

- `VPN-Pula-Muro-Instalador-2.0.19-r5.exe` (+ `.sha256`): o instalador;
- `GoLiveBypass-2.0.19.exe`: o app portátil que vai na release pro atualizador automático.

## 🏷️ Versões

O instalador se chama `VPN-Pula-Muro-Instalador-<versão do app>-r<revisão>.exe` (até a r4: `GoLiveBypass-Instalador-...`). A revisão muda quando o instalador muda, mesmo com o app igual. Pra saber qual tá num PC, veja em **Configurações → Aplicativos** ou rode `reg query HKCU\Software\GoLiveBypass-Instalador /v Versao` (a r1 não grava esse valor).

| Revisão | Data | App | O que mudou |
|---|---|---|---|
| **r5** | 25/11/2026 | 2.0.19 | Vira **VPN Pula Muro**: nome, verde e amarelo, caramelo. App 2.0.19 com o login da Proton de volta (código 5003). Corrige o helper do Proton sumindo quando o exe era aberto com o app rodando. Bug report abre issue aqui, e as atualizações vêm das releases daqui. |
| r4 | 13/11/2026 | 2.0.16 | Fixa a rota antes de abrir a janela e espera a medição terminar (a r3 era desfeita pela própria janela do app). |
| r3 | 11/11/2026 | 2.0.16 | Fixa a rota medida na primeira ativação: o Firewall para de perguntar a cada boot. |
| r2 | 08/11/2026 | 2.0.16 | Inicialização por tarefa agendada no lugar da entrada no registro, que o Windows às vezes pulava. |
| r1 | 06/11/2026 | 2.0.16 | Primeira versão: atalho "Discord com VPN" e bloqueio do autostart do Discord. |

## 📜 Licença e créditos

GPLv3, a mesma do projeto original (veja [LICENSE](LICENSE)).

- **GoLiveBypass** é do [bezumiya](https://github.com/bezumiya/GoLiveBypass) e dos [colaboradores](https://github.com/bezumiya/GoLiveBypass#agradecimentos). O código do app é o da tag oficial mais o [`edicao/uxuchoa.patch`](edicao/uxuchoa.patch), e cada release traz o zip do código-fonte usado no build.
- **WireSock** e **ProtonVPN** são produtos dos seus respectivos donos. A VPN Pula Muro não tem ligação com eles, nem com o Discord.
- O **caramelo** é pixel art feita pra este projeto.
