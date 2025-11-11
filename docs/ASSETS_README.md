# README - Estrutura de Assets

## Organização dos Assets por Cliente

Esta pasta contém os assets organizados por cliente:

### `/assets/images/guara/`
- Assets específicos do cliente Guará
- Inclui: logo.png, ícones personalizados, imagens de marca

### `/assets/images/vale_das_minas/`
- Assets específicos do cliente Vale das Minas
- Inclui: logo.png, ícones personalizados, imagens de marca

### `/assets/images/common/`
- Assets compartilhados entre todos os clientes
- Inclui: ícones genéricos, placeholder images, backgrounds

## Como adicionar assets para um novo cliente:

1. Crie uma nova pasta com o ID do cliente (ex: `/assets/images/novo_cliente/`)
2. Adicione os assets específicos na pasta
3. Atualize a configuração em `ClientConfig.fromClientType()`
4. Adicione os novos assets no `pubspec.yaml`

## Formatos recomendados:
- Logo: PNG com fundo transparente
- Ícones: SVG ou PNG (24x24, 48x48, 72x72)
- Imagens: PNG ou JPG otimizados