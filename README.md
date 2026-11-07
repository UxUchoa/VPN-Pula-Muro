# GoLiveBypass: instalador "Discord com VPN"

Instalador **não oficial** do [GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), feito pra quem quer **dar dois cliques no atalho e já ter o Discord com Go Live funcionando**: a VPN sobe primeiro e o Discord abre já por ela.

> O GoLiveBypass é do [bezumiya](https://github.com/bezumiya/GoLiveBypass) e é GPLv3. Este repositório só compila a tag oficial, sem alterar nada, e empacota com um instalador. Bugs do app em si vão pra [issues do projeto original](https://github.com/bezumiya/GoLiveBypass/issues). Bugs do instalador vêm [pra cá](https://github.com/UxUchoa/GoLiveBypass-Instalador/issues).

## Como usar

1. Baixe o `GoLiveBypass-Instalador-x.y.z.exe` na página de [Releases](https://github.com/UxUchoa/GoLiveBypass-Instalador/releases).
2. Dê dois cliques. Como o instalador não tem assinatura digital, o Windows pode mostrar "O Windows protegeu o computador". Clique em **Mais informações → Executar assim mesmo**.
3. Se quiser, marque **Iniciar com o Windows**. Aí, ao ligar o PC, a VPN sobe e o Discord abre já por ela, sem abrir a janela do bypass.
4. No fim, deixe marcado **Abrir o GoLiveBypass agora**, entre com a sua conta **Proton** (a grátis serve) e clique em **Ativar**.
   Na primeira ativação o app baixa e instala o **WireSock** oficial, o motor da VPN. O Windows vai pedir administrador.
5. Pronto. Dali em diante use o atalho **Discord com VPN** na área de trabalho ou no Menu Iniciar.

### Coisas importantes

- Só o **Discord** passa pela VPN. O resto do PC (jogos, navegador) continua na sua internet normal.
- Para fechar, use **Sair** no ícone da bandeja (botão direito). Se você usar **Desativar**, a VPN fica desligada de vez, e o atalho só abre o app sem ligar a VPN. Pra voltar, é só abrir o GoLiveBypass e Ativar de novo.
- Se o Discord também inicia sozinho com o Windows, ele abre primeiro sem VPN e o bypass fecha e reabre ele pelo túnel. Funciona, mas pisca. Pra evitar, desligue "Abrir o Discord" em Configurações do Discord → Configurações do Windows.
- O app se atualiza sozinho pelas releases oficiais do bezumiya/GoLiveBypass.

## O que o instalador faz

| O quê | Onde |
| --- | --- |
| Instala o app (só pro seu usuário, sem admin) | `%LOCALAPPDATA%\Programs\GoLiveBypass\GoLiveBypass.exe` |
| Atalho "Discord com VPN" (`GoLiveBypass.exe --hidden`) | Área de trabalho e Menu Iniciar |
| Atalho "GoLiveBypass (configurar)" | Menu Iniciar (e na área de trabalho, se marcar) |
| Iniciar com o Windows (opcional) | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\GoLiveBypass` |

O `--hidden` é um recurso do próprio GoLiveBypass: ele sobe só na bandeja e, se da última vez a VPN tava ativa, usa a sua sessão Proton salva, liga o túnel e só depois reabre o Discord por ele. É o mesmo comando que o botão "Iniciar com Windows" do app usa.

## Desinstalar

Configurações do Windows → Aplicativos → **GoLiveBypass (Discord com VPN)** → Desinstalar. Isso remove o app, os atalhos e a entrada de inicialização. O login do Proton e as configurações ficam em `%LOCALAPPDATA%\GoLiveBypass`. Apague essa pasta se quiser limpar tudo. O WireSock fica instalado como programa separado, e dá pra remover em Aplicativos.

## Compilar você mesmo

Precisa de Git, Node.js 24+, Go 1.26+ e [Inno Setup 6](https://jrsoftware.org/isinfo.php).

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.16
```

O script clona a tag `v2.0.16` do repositório oficial, roda `npm ci` e `npm run build:win` (o mesmo build do projeto) e gera `dist\GoLiveBypass-Instalador-2.0.16.exe` com o `.sha256` ao lado.

## Licença

GPLv3, a mesma do projeto original (veja [LICENSE](LICENSE)). O código-fonte do app vem da tag oficial correspondente em [bezumiya/GoLiveBypass](https://github.com/bezumiya/GoLiveBypass), e cada release daqui também traz o zip do código-fonte usado.
