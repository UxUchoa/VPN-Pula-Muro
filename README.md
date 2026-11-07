# GoLiveBypass: instalador "Discord com VPN"

Instalador **não oficial** do [GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), feito pra quem quer **ligar o PC (ou clicar num atalho) e já ter o Discord com Go Live funcionando**: a VPN sobe primeiro e o Discord abre já por ela.

> O GoLiveBypass é do [bezumiya](https://github.com/bezumiya/GoLiveBypass) e é GPLv3. Este repositório **compila a tag oficial sem alterar nada** e empacota com um instalador. Login no Proton, escolha de rota e VPN são exatamente os do app original. Bugs do app vão pras [issues do projeto original](https://github.com/bezumiya/GoLiveBypass/issues). Bugs do instalador vêm [pra cá](https://github.com/UxUchoa/GoLiveBypass-Instalador/issues).

## Download

**[⬇️ Baixar o instalador (última versão)](https://github.com/UxUchoa/GoLiveBypass-Instalador/releases/latest)**: baixe o arquivo `GoLiveBypass-Instalador-x.y.z.exe`.

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

   Se responder **Não**, nada muda na inicialização. Antes de avançar ainda dá pra marcar ou desmarcar as caixinhas.
5. **Avançar → Concluir.** Pronto.

### No dia a dia

- **Ligou o PC** (com "Iniciar com o Windows" marcado): é só esperar. A VPN sobe e o Discord abre sozinho, pronto pra compartilhar a tela.
- **Quer abrir na mão:** clique no atalho **Discord com VPN**, na área de trabalho ou no Menu Iniciar. Ele liga a VPN e abre o Discord por ela, em uns 30 segundos.
- **Pra fechar:** botão direito no ícone do GoLiveBypass na bandeja → **Sair**.
  ⚠️ **Não use "Desativar"**. Ele desliga a VPN de vez, e aí o atalho e a inicialização só abrem o app sem ligar a VPN. Se fizer isso sem querer, abra o **GoLiveBypass (configurar)** e clique em **Ativar** de novo.
- **Mudar conta, rota ou configurações:** Menu Iniciar → **GoLiveBypass (configurar)**.

### Pulei as opções no instalador. E agora?

- **Iniciar com o Windows:** no GoLiveBypass, botão direito no ícone da bandeja → **Iniciar com Windows**.
- **Impedir o Discord de abrir sozinho:** Configurações do Windows → Aplicativos → **Inicialização** → desligue o **Discord**. Ou, no Discord, Configurações → **Configurações do Windows** → desligue **Abrir o Discord**.

## Como funciona

- Só o **Discord** passa pela VPN (WireGuard da ProtonVPN, via WireSock). Jogos, navegador e o resto do PC continuam na sua internet normal.
- O atalho e a inicialização rodam `GoLiveBypass.exe --hidden`, um recurso do próprio app: ele sobe só na bandeja e, se da última vez a VPN tava ativa, usa a sua sessão Proton salva, liga o túnel e só depois reabre o Discord por ele.
- O app se atualiza sozinho pelas releases oficiais do bezumiya/GoLiveBypass.

| O que o instalador mexe | Onde |
| --- | --- |
| App | `%LOCALAPPDATA%\Programs\GoLiveBypass\GoLiveBypass.exe` |
| Atalho **Discord com VPN** (`--hidden`) | Área de trabalho e Menu Iniciar |
| Atalho **GoLiveBypass (configurar)** | Menu Iniciar (e área de trabalho, se marcar) |
| Iniciar com o Windows (opcional) | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\GoLiveBypass` |
| Bloquear o Discord na inicialização (opcional) | O interruptor do Discord em Aplicativos → Inicialização (`StartupApproved\Run`) |

## Desinstalar

Configurações do Windows → Aplicativos → **GoLiveBypass (Discord com VPN)** → Desinstalar.

Isso remove o app, os atalhos e a inicialização, e **devolve o Discord pra iniciar sozinho** se foi o instalador que bloqueou. O login do Proton e as configurações ficam em `%LOCALAPPDATA%\GoLiveBypass`. Apague essa pasta se quiser limpar tudo. O WireSock fica como programa separado em Aplicativos.

## Instalação silenciosa (pra quem manja)

```powershell
GoLiveBypass-Instalador-2.0.16.exe /VERYSILENT /INICIAR=1 /BLOQUEARDISCORD=1
```

`/INICIAR=1` liga a inicialização com o Windows e `/BLOQUEARDISCORD=1` bloqueia o autostart do Discord. O login no Proton continua sendo feito no app. Se o GoLiveBypass estiver aberto, o instalador silencioso sai com código 1 sem mexer em nada.

## Compilar você mesmo

Precisa de Git, Node.js 24+, Go 1.26+ e [Inno Setup 6](https://jrsoftware.org/isinfo.php).

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.16
```

O script clona a tag `v2.0.16` do repositório oficial, roda `npm ci` e `npm run build:win` (o mesmo build do projeto) e gera `dist\GoLiveBypass-Instalador-2.0.16.exe` com o `.sha256` ao lado.

## Licença

GPLv3, a mesma do projeto original (veja [LICENSE](LICENSE)). O código-fonte do app é o da tag oficial correspondente em [bezumiya/GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), e cada release daqui também traz o zip do código-fonte usado no build.
